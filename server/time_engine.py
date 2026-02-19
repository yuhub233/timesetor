import yaml
from datetime import datetime, timedelta, time, date
from typing import Optional, Dict, Tuple
import os

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "config.yaml")

def load_config():
    with open(CONFIG_PATH, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)

_config = None

def get_config():
    global _config
    if _config is None:
        _config = load_config()
    return _config

def reload_config():
    global _config
    _config = load_config()
    return _config

def time_str_to_minutes(time_str: str) -> int:
    parts = time_str.split(':')
    return int(parts[0]) * 60 + int(parts[1])

def minutes_to_time_str(minutes: int) -> str:
    hours = (minutes // 60) % 24
    mins = minutes % 60
    return f"{hours:02d}:{mins:02d}"

def approach_time(current_minutes: int, target_minutes: int, rate: float) -> int:
    diff = target_minutes - current_minutes
    
    if abs(diff) <= 1:
        return target_minutes
    
    if diff > 0:
        if diff > 720:
            new_minutes = current_minutes - int((1440 - diff) * rate)
        else:
            new_minutes = current_minutes + int(diff * rate)
    else:
        if abs(diff) > 720:
            new_minutes = current_minutes + int((1440 + diff) * rate)
        else:
            new_minutes = current_minutes + int(diff * rate)
    
    return new_minutes % 1440

def calculate_virtual_wake_time(real_wake_time: datetime, target_wake_str: str,
                                 approach_rate: float) -> Tuple[datetime, str]:
    target_minutes = time_str_to_minutes(target_wake_str)
    real_minutes = real_wake_time.hour * 60 + real_wake_time.minute
    
    virtual_minutes = approach_time(real_minutes, target_minutes, approach_rate)
    
    virtual_time = real_wake_time.replace(
        hour=virtual_minutes // 60,
        minute=virtual_minutes % 60,
        second=0,
        microsecond=0
    )
    
    display = minutes_to_time_str(virtual_minutes)
    
    return virtual_time, display

def calculate_expected_sleep_time(yesterday_sleep: datetime, target_sleep_str: str,
                                   approach_rate: float) -> datetime:
    target_minutes = time_str_to_minutes(target_sleep_str)
    yesterday_minutes = yesterday_sleep.hour * 60 + yesterday_sleep.minute
    
    expected_minutes = approach_time(yesterday_minutes, target_minutes, approach_rate)
    
    today = date.today()
    expected_sleep = datetime.combine(today, time(expected_minutes // 60, expected_minutes % 60))
    
    if expected_minutes < 720:
        expected_sleep += timedelta(days=1)
    
    return expected_sleep

def calculate_entertainment_multiplier(real_wake: datetime, expected_sleep: datetime,
                                        virtual_wake: datetime, yesterday_virtual_sleep: datetime,
                                        target_entertainment_hours: float,
                                        target_study_hours: float) -> float:
    real_awake_seconds = (expected_sleep - real_wake).total_seconds()
    real_awake_minutes = real_awake_seconds / 60
    
    if yesterday_virtual_sleep:
        virtual_awake_seconds = 24 * 3600 - (virtual_wake - yesterday_virtual_sleep).total_seconds()
        if virtual_awake_seconds < 0:
            virtual_awake_seconds += 24 * 3600
    else:
        virtual_awake_seconds = 24 * 3600
    virtual_awake_minutes = virtual_awake_seconds / 60
    
    target_entertainment_minutes = target_entertainment_hours * 60
    target_study_minutes = target_study_hours * 60
    
    virtual_rest_minutes = virtual_awake_minutes - target_entertainment_minutes - target_study_minutes
    real_rest_minutes = real_awake_minutes - target_entertainment_minutes - target_study_minutes
    
    if virtual_rest_minutes <= 0:
        return 1.0
    
    if real_rest_minutes <= 0:
        return 10.0
    
    x = (2 * virtual_awake_minutes - target_study_minutes - real_awake_minutes + target_entertainment_minutes) / (2 * target_entertainment_minutes)
    
    x = max(0.5, min(10.0, x))
    
    return x

class TimeEngine:
    def __init__(self, user_id: int, config_override: Dict = None):
        self.user_id = user_id
        self.config = config_override or get_config()
        self.time_config = self.config['time']
        
        self.current_speed = self.time_config['normal_speed']
        self.current_activity = 'rest'
        
        self.virtual_time_offset = timedelta(0)
        self.last_update_time = None
        
        self.study_start_time = None
        self.study_planned_duration = 0
        self.study_elapsed_seconds = 0
        
    def initialize_day(self, real_wake_time: datetime, 
                       yesterday_sleep: datetime = None,
                       yesterday_virtual_sleep: datetime = None):
        target_wake = self.time_config['target_wake_time']
        target_sleep = self.time_config['target_sleep_time']
        approach_rate = self.time_config['time_approach_rate']
        
        virtual_wake, virtual_wake_display = calculate_virtual_wake_time(
            real_wake_time, target_wake, approach_rate
        )
        
        if yesterday_sleep:
            expected_sleep = calculate_expected_sleep_time(
                yesterday_sleep, target_sleep, approach_rate
            )
        else:
            target_minutes = time_str_to_minutes(target_sleep)
            today = date.today()
            expected_sleep = datetime.combine(today, time(target_minutes // 60, target_minutes % 60))
            if target_minutes < 720:
                expected_sleep += timedelta(days=1)
        
        entertainment_multiplier = calculate_entertainment_multiplier(
            real_wake_time, expected_sleep,
            virtual_wake, yesterday_virtual_sleep,
            self.time_config['target_entertainment_hours'],
            self.time_config['target_study_hours']
        )
        
        self.virtual_time_offset = virtual_wake - real_wake_time
        self.last_update_time = real_wake_time
        
        return {
            'virtual_wake_time': virtual_wake,
            'virtual_wake_display': virtual_wake_display,
            'expected_sleep_time': expected_sleep,
            'entertainment_multiplier': entertainment_multiplier
        }
    
    def update_activity(self, activity_type: str, 
                        app_name: str = None,
                        entertainment_apps: list = None,
                        study_apps: list = None):
        self.current_activity = activity_type
        
        if activity_type == 'sleep':
            self.current_speed = 0
        elif activity_type == 'entertainment':
            entertainment_multiplier = getattr(self, 'entertainment_multiplier', 
                                               self.time_config['entertainment_base_speed'])
            self.current_speed = entertainment_multiplier
        elif activity_type == 'study':
            self.study_start_time = datetime.now()
            self.study_planned_duration = self.time_config.get('study_transition_minutes', 60) * 60
            self.current_speed = self._calculate_study_speed()
        elif activity_type == 'pomodoro_break':
            self.current_speed = self.time_config.get('break_speed', 1.0)
        else:
            self.current_speed = self.time_config['rest_speed']
        
        return self.current_speed
    
    def start_study_session(self, planned_duration_minutes: int):
        self.study_start_time = datetime.now()
        self.study_planned_duration = planned_duration_minutes * 60
        self.study_elapsed_seconds = 0
        self.current_activity = 'study'
        
    def _calculate_study_speed(self) -> float:
        if self.study_start_time is None or self.study_planned_duration <= 0:
            return self.time_config['study_end_speed']
        
        elapsed = (datetime.now() - self.study_start_time).total_seconds()
        self.study_elapsed_seconds = elapsed
        
        if elapsed >= self.study_planned_duration:
            return self.time_config['study_end_speed']
        
        progress = elapsed / self.study_planned_duration
        
        start_speed = self.time_config['study_start_speed']
        end_speed = self.time_config['study_end_speed']
        curve_type = self.time_config.get('study_curve_type', 'linear')
        
        if curve_type == 'linear':
            speed = start_speed - (start_speed - end_speed) * progress
        elif curve_type == 'exponential':
            speed = start_speed * ((end_speed / start_speed) ** progress)
        elif curve_type == 'ease_out':
            speed = start_speed - (start_speed - end_speed) * (1 - (1 - progress) ** 2)
        else:
            speed = start_speed - (start_speed - end_speed) * progress
        
        return max(end_speed, speed)
    
    def get_virtual_time(self, real_time: datetime = None) -> Tuple[datetime, str]:
        if real_time is None:
            real_time = datetime.now()
        
        if self.last_update_time is None:
            self.last_update_time = real_time
            return real_time + self.virtual_time_offset, real_time.strftime("%H:%M")
        
        elapsed = (real_time - self.last_update_time).total_seconds()
        virtual_elapsed = elapsed * self.current_speed
        
        self.virtual_time_offset += timedelta(seconds=virtual_elapsed - elapsed)
        self.last_update_time = real_time
        
        virtual_time = real_time + self.virtual_time_offset
        display = virtual_time.strftime("%H:%M")
        
        return virtual_time, display
    
    def get_current_speed(self) -> float:
        if self.current_activity == 'study':
            return self._calculate_study_speed()
        return self.current_speed
    
    def set_entertainment_multiplier(self, multiplier: float):
        self.entertainment_multiplier = multiplier
        if self.current_activity == 'entertainment':
            self.current_speed = multiplier
    
    def record_sleep(self, real_sleep_time: datetime) -> Tuple[datetime, str]:
        virtual_time, display = self.get_virtual_time(real_sleep_time)
        return virtual_time, display
    
    def get_study_progress(self) -> Dict:
        if self.study_start_time is None:
            return {'active': False}
        
        elapsed = (datetime.now() - self.study_start_time).total_seconds()
        progress = min(1.0, elapsed / self.study_planned_duration) if self.study_planned_duration > 0 else 0
        
        return {
            'active': True,
            'elapsed_seconds': int(elapsed),
            'planned_seconds': self.study_planned_duration,
            'progress': progress,
            'current_speed': self._calculate_study_speed(),
            'remaining_seconds': max(0, self.study_planned_duration - int(elapsed))
        }

def calculate_daily_stats(real_wake: datetime, real_sleep: datetime,
                          virtual_wake: datetime, virtual_sleep: datetime,
                          time_logs: list) -> Dict:
    real_awake_seconds = (real_sleep - real_wake).total_seconds()
    virtual_awake_seconds = (virtual_sleep - virtual_wake).total_seconds()
    
    stats = {
        'real_awake_hours': real_awake_seconds / 3600,
        'virtual_awake_hours': virtual_awake_seconds / 3600,
        'entertainment_minutes': 0,
        'study_minutes': 0,
        'rest_minutes': 0,
        'virtual_entertainment_minutes': 0,
        'virtual_study_minutes': 0,
        'virtual_rest_minutes': 0,
    }
    
    for log in time_logs:
        duration_minutes = log.get('duration_seconds', 0) / 60
        speed = log.get('speed_multiplier', 1.0)
        activity = log.get('activity_type', 'rest')
        
        if activity == 'entertainment':
            stats['entertainment_minutes'] += duration_minutes
            stats['virtual_entertainment_minutes'] += duration_minutes * speed
        elif activity == 'study':
            stats['study_minutes'] += duration_minutes
            stats['virtual_study_minutes'] += duration_minutes * speed
        else:
            stats['rest_minutes'] += duration_minutes
            stats['virtual_rest_minutes'] += duration_minutes * speed
    
    return stats
