from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime, date, timedelta
import yaml
import os
import json

from database import (
    init_database, create_user, get_user_by_username, get_user_by_id,
    update_user_settings, get_or_create_daily_record, update_daily_record,
    get_daily_record, get_recent_daily_records, add_time_log, get_time_logs,
    add_pomodoro_session, update_pomodoro_session, get_pomodoro_sessions,
    add_ai_summary, get_ai_summaries, register_device,
    get_yesterday_sleep_time, get_yesterday_virtual_sleep_time
)
from time_engine import TimeEngine, get_config
from crypto import (
    get_today_key, hash_password, verify_password,
    generate_token, verify_token
)
from ai_service import AIService

app = Flask(__name__)
CORS(app)

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "config.yaml")

user_engines = {}
user_sessions = {}

def load_config():
    with open(CONFIG_PATH, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)

def get_encryption_key():
    config = load_config()
    salt = config['security']['encryption_salt']
    return get_today_key(salt)

def get_user_engine(user_id: int) -> TimeEngine:
    if user_id not in user_engines:
        user_engines[user_id] = TimeEngine(user_id)
    return user_engines[user_id]

def require_auth(f):
    def decorated(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({'error': 'Missing authorization token'}), 401
        token = auth_header[7:]
        key = get_encryption_key()
        config = load_config()
        expiry = config['security']['token_expiry_hours']
        user_id = verify_token(token, key, expiry)
        if user_id is None:
            return jsonify({'error': 'Invalid or expired token'}), 401
        request.user_id = user_id
        return f(*args, **kwargs)
    decorated.__name__ = f.__name__
    return decorated

@app.route('/api/auth/register', methods=['POST'])
def register():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    if not username or not password:
        return jsonify({'error': 'Username and password required'}), 400
    if get_user_by_username(username):
        return jsonify({'error': 'Username already exists'}), 400
    config = load_config()
    salt = config['security']['encryption_salt']
    password_hash = hash_password(password, salt)
    initial_settings = {
        'target_wake_time': config['time']['target_wake_time'],
        'target_sleep_time': config['time']['target_sleep_time'],
        'target_entertainment_hours': config['time']['target_entertainment_hours'],
        'target_study_hours': config['time']['target_study_hours'],
        'time_approach_rate': config['time']['time_approach_rate']
    }
    user_id = create_user(username, password_hash, initial_settings)
    key = get_encryption_key()
    token = generate_token(user_id, datetime.now(), key)
    return jsonify({'success': True, 'user_id': user_id, 'token': token})

@app.route('/api/auth/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    if not username or not password:
        return jsonify({'error': 'Username and password required'}), 400
    user = get_user_by_username(username)
    if not user:
        return jsonify({'error': 'Invalid credentials'}), 401
    config = load_config()
    salt = config['security']['encryption_salt']
    if not verify_password(password, salt, user['password_hash']):
        return jsonify({'error': 'Invalid credentials'}), 401
    key = get_encryption_key()
    token = generate_token(user['id'], datetime.now(), key)
    return jsonify({
        'success': True,
        'user_id': user['id'],
        'token': token,
        'settings': json.loads(user['settings']) if user['settings'] else {}
    })

@app.route('/api/user/settings', methods=['GET', 'PUT'])
@require_auth
def user_settings():
    user_id = request.user_id
    if request.method == 'GET':
        user = get_user_by_id(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        settings = json.loads(user['settings']) if user['settings'] else {}
        return jsonify({'settings': settings})
    elif request.method == 'PUT':
        data = request.get_json()
        settings = data.get('settings', {})
        if update_user_settings(user_id, settings):
            return jsonify({'success': True})
        return jsonify({'error': 'Failed to update settings'}), 500

@app.route('/api/time/wake', methods=['POST'])
@require_auth
def record_wake():
    user_id = request.user_id
    data = request.get_json()
    wake_time_str = data.get('wake_time')
    wake_time = datetime.fromisoformat(wake_time_str) if wake_time_str else datetime.now()
    today = date.today()
    daily_record = get_or_create_daily_record(user_id, today)
    if daily_record.get('real_wake_time'):
        return jsonify({'error': 'Already recorded wake time today'}), 400
    yesterday_sleep = get_yesterday_sleep_time(user_id)
    yesterday_virtual_sleep = get_yesterday_virtual_sleep_time(user_id)
    engine = get_user_engine(user_id)
    init_data = engine.initialize_day(wake_time, yesterday_sleep, yesterday_virtual_sleep)
    update_daily_record(daily_record['id'],
        real_wake_time=wake_time.isoformat(),
        virtual_wake_time=init_data['virtual_wake_time'].isoformat(),
        real_wake_time_display=init_data['virtual_wake_display'],
        target_entertainment_hours=engine.time_config['target_entertainment_hours'],
        target_study_hours=engine.time_config['target_study_hours']
    )
    user_sessions[user_id] = {'wake_time': wake_time, 'last_activity': 'rest', 'last_update': wake_time}
    return jsonify({'success': True, 'virtual_wake_time': init_data['virtual_wake_display'], 'entertainment_multiplier': 2.0})

@app.route('/api/time/sleep', methods=['POST'])
@require_auth
def record_sleep():
    user_id = request.user_id
    data = request.get_json()
    sleep_time_str = data.get('sleep_time')
    sleep_time = datetime.fromisoformat(sleep_time_str) if sleep_time_str else datetime.now()
    today = date.today()
    daily_record = get_daily_record(user_id, today)
    if not daily_record or not daily_record.get('real_wake_time'):
        return jsonify({'error': 'Must record wake time first'}), 400
    engine = get_user_engine(user_id)
    virtual_sleep_time, virtual_sleep_display = engine.record_sleep(sleep_time)
    update_daily_record(daily_record['id'],
        real_sleep_time=sleep_time.isoformat(),
        virtual_sleep_time=virtual_sleep_time.isoformat(),
        virtual_sleep_time_display=virtual_sleep_display,
        status='completed'
    )
    if user_id in user_sessions:
        del user_sessions[user_id]
    if user_id in user_engines:
        del user_engines[user_id]
    return jsonify({'success': True, 'virtual_sleep_time': virtual_sleep_display})

@app.route('/api/time/current', methods=['GET'])
@require_auth
def get_current_time():
    user_id = request.user_id
    today = date.today()
    daily_record = get_daily_record(user_id, today)
    if not daily_record or not daily_record.get('real_wake_time'):
        return jsonify({'status': 'not_awake', 'message': 'Please record your wake time first'})
    engine = get_user_engine(user_id)
    virtual_time, display = engine.get_virtual_time()
    return jsonify({
        'status': 'awake',
        'real_time': datetime.now().isoformat(),
        'virtual_time': virtual_time.isoformat(),
        'virtual_time_display': display,
        'current_speed': engine.get_current_speed(),
        'current_activity': engine.current_activity
    })

@app.route('/api/activity/update', methods=['POST'])
@require_auth
def update_activity():
    user_id = request.user_id
    data = request.get_json()
    activity_type = data.get('activity_type', 'rest')
    app_name = data.get('app_name')
    config = load_config()
    entertainment_apps = config['android'].get('entertainment_apps', [])
    study_apps = config['android'].get('study_apps', [])
    engine = get_user_engine(user_id)
    speed = engine.update_activity(activity_type, app_name, entertainment_apps, study_apps)
    return jsonify({'success': True, 'activity_type': activity_type, 'speed': speed})

@app.route('/api/pomodoro/start', methods=['POST'])
@require_auth
def start_pomodoro():
    user_id = request.user_id
    data = request.get_json()
    duration = data.get('duration_minutes', 25)
    session_type = data.get('session_type', 'work')
    today = date.today()
    daily_record = get_or_create_daily_record(user_id, today)
    engine = get_user_engine(user_id)
    virtual_start, _ = engine.get_virtual_time()
    session_id = add_pomodoro_session(
        user_id=user_id, daily_record_id=daily_record['id'],
        start_time=datetime.now(), planned_duration=duration,
        session_type=session_type, virtual_start_time=virtual_start
    )
    if session_type == 'work':
        engine.start_study_session(duration)
    return jsonify({'success': True, 'session_id': session_id})

@app.route('/api/pomodoro/end', methods=['POST'])
@require_auth
def end_pomodoro():
    user_id = request.user_id
    data = request.get_json()
    session_id = data.get('session_id')
    actual_duration = data.get('actual_duration_minutes')
    status = data.get('status', 'completed')
    engine = get_user_engine(user_id)
    virtual_end, _ = engine.get_virtual_time()
    update_pomodoro_session(session_id,
        end_time=datetime.now().isoformat(),
        actual_duration_minutes=actual_duration,
        virtual_end_time=virtual_end.isoformat(),
        status=status
    )
    engine.update_activity('rest')
    return jsonify({'success': True})

@app.route('/api/data/daily', methods=['GET'])
@require_auth
def get_daily_data():
    user_id = request.user_id
    target_date_str = request.args.get('date')
    target_date = date.fromisoformat(target_date_str) if target_date_str else date.today()
    daily_record = get_daily_record(user_id, target_date)
    if not daily_record:
        return jsonify({'error': 'No record for this date'}), 404
    time_logs = get_time_logs(user_id, target_date)
    pomodoro_sessions = get_pomodoro_sessions(user_id, target_date)
    return jsonify({'daily_record': daily_record, 'time_logs': time_logs, 'pomodoro_sessions': pomodoro_sessions})

@app.route('/api/data/weekly', methods=['GET'])
@require_auth
def get_weekly_data():
    user_id = request.user_id
    records = get_recent_daily_records(user_id, 7)
    return jsonify({'records': records})

@app.route('/api/summaries', methods=['GET'])
@require_auth
def get_summaries():
    user_id = request.user_id
    summary_type = request.args.get('type')
    limit = request.args.get('limit', 10, type=int)
    summaries = get_ai_summaries(user_id, summary_type, limit)
    return jsonify({'summaries': summaries})

@app.route('/api/summaries/generate', methods=['POST'])
@require_auth
def generate_summary():
    user_id = request.user_id
    data = request.get_json()
    summary_type = data.get('type', 'daily')
    ai_service = AIService()
    if not ai_service.is_enabled():
        return jsonify({'error': 'AI service not configured'}), 400
    if summary_type == 'daily':
        today = date.today()
        daily_record = get_daily_record(user_id, today)
        if not daily_record:
            return jsonify({'error': 'No daily record found'}), 404
        summary = ai_service.generate_daily_summary(daily_record)
        if summary:
            add_ai_summary(user_id, 'daily', today, today, summary, daily_record)
            return jsonify({'success': True, 'summary': summary})
    return jsonify({'error': 'Failed to generate summary'}), 500

@app.route('/api/config', methods=['GET'])
@require_auth
def get_config_route():
    config = load_config()
    safe_config = {
        'time': config['time'],
        'pomodoro': config['pomodoro'],
        'display': config['display'],
        'android': {'entertainment_apps': config['android']['entertainment_apps'], 'study_apps': config['android']['study_apps']}
    }
    return jsonify(safe_config)

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'ok', 'timestamp': datetime.now().isoformat()})

def run_server():
    config = load_config()
    host = config['server']['host']
    port = config['server']['port']
    print(f"TimeSetor Server starting on {host}:{port}")
    app.run(host=host, port=port, debug=False, threaded=True)

if __name__ == '__main__':
    init_database()
    run_server()