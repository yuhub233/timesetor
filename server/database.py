import sqlite3
import os
from datetime import datetime, date
from typing import Optional, List, Dict, Any
import json

DB_PATH = os.path.join(os.path.dirname(__file__), "timesetor.db")

def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_database():
    conn = get_connection()
    cursor = conn.cursor()
    
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            settings TEXT DEFAULT '{}'
        )
    """)
    
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS daily_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            date DATE NOT NULL,
            real_wake_time TIMESTAMP,
            real_sleep_time TIMESTAMP,
            virtual_wake_time TIMESTAMP,
            virtual_sleep_time TIMESTAMP,
            real_wake_time_display TEXT,
            target_entertainment_hours REAL,
            target_study_hours REAL,
            actual_entertainment_minutes INTEGER DEFAULT 0,
            actual_study_minutes INTEGER DEFAULT 0,
            actual_rest_minutes INTEGER DEFAULT 0,
            virtual_entertainment_minutes INTEGER DEFAULT 0,
            virtual_study_minutes INTEGER DEFAULT 0,
            virtual_rest_minutes INTEGER DEFAULT 0,
            entertainment_speed_multiplier REAL DEFAULT 2.0,
            status TEXT DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id),
            UNIQUE(user_id, date)
        )
    """)
    
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS time_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            daily_record_id INTEGER NOT NULL,
            real_timestamp TIMESTAMP NOT NULL,
            virtual_timestamp TIMESTAMP,
            virtual_time_display TEXT,
            activity_type TEXT NOT NULL,
            speed_multiplier REAL DEFAULT 1.0,
            duration_seconds INTEGER DEFAULT 0,
            app_name TEXT,
            notes TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id),
            FOREIGN KEY (daily_record_id) REFERENCES daily_records(id)
        )
    """)
    
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS pomodoro_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            daily_record_id INTEGER NOT NULL,
            start_time TIMESTAMP NOT NULL,
            end_time TIMESTAMP,
            planned_duration_minutes INTEGER NOT NULL,
            actual_duration_minutes INTEGER,
            break_duration_minutes INTEGER DEFAULT 0,
            session_type TEXT DEFAULT 'work',
            virtual_start_time TIMESTAMP,
            virtual_end_time TIMESTAMP,
            status TEXT DEFAULT 'completed',
            notes TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id),
            FOREIGN KEY (daily_record_id) REFERENCES daily_records(id)
        )
    """)
    
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS ai_summaries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            summary_type TEXT NOT NULL,
            period_start DATE NOT NULL,
            period_end DATE NOT NULL,
            summary_text TEXT NOT NULL,
            source_data TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )
    """)
    
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS devices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            device_id TEXT NOT NULL,
            device_name TEXT,
            device_type TEXT,
            last_active TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id),
            UNIQUE(user_id, device_id)
        )
    """)
    
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS app_usage_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            device_id TEXT NOT NULL,
            app_package TEXT NOT NULL,
            app_name TEXT,
            start_time TIMESTAMP NOT NULL,
            end_time TIMESTAMP,
            duration_seconds INTEGER DEFAULT 0,
            activity_type TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )
    """)
    
    conn.commit()
    conn.close()

def create_user(username: str, password_hash: str, settings: Dict = None) -> int:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "INSERT INTO users (username, password_hash, settings) VALUES (?, ?, ?)",
            (username, password_hash, json.dumps(settings or {}))
        )
        conn.commit()
        return cursor.lastrowid
    finally:
        conn.close()

def get_user_by_username(username: str) -> Optional[Dict]:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT * FROM users WHERE username = ?", (username,))
        row = cursor.fetchone()
        if row:
            return dict(row)
        return None
    finally:
        conn.close()

def get_user_by_id(user_id: int) -> Optional[Dict]:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
        row = cursor.fetchone()
        if row:
            return dict(row)
        return None
    finally:
        conn.close()

def update_user_settings(user_id: int, settings: Dict) -> bool:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "UPDATE users SET settings = ? WHERE id = ?",
            (json.dumps(settings), user_id)
        )
        conn.commit()
        return cursor.rowcount > 0
    finally:
        conn.close()

def get_or_create_daily_record(user_id: int, record_date: date) -> Dict:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "SELECT * FROM daily_records WHERE user_id = ? AND date = ?",
            (user_id, record_date.isoformat())
        )
        row = cursor.fetchone()
        if row:
            return dict(row)
        
        cursor.execute(
            """INSERT INTO daily_records (user_id, date) VALUES (?, ?)""",
            (user_id, record_date.isoformat())
        )
        conn.commit()
        
        cursor.execute(
            "SELECT * FROM daily_records WHERE id = ?",
            (cursor.lastrowid,)
        )
        return dict(cursor.fetchone())
    finally:
        conn.close()

def update_daily_record(record_id: int, **kwargs) -> bool:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        set_clauses = []
        values = []
        for key, value in kwargs.items():
            set_clauses.append(f"{key} = ?")
            values.append(value)
        
        if not set_clauses:
            return False
        
        set_clauses.append("updated_at = CURRENT_TIMESTAMP")
        values.append(record_id)
        
        query = f"UPDATE daily_records SET {', '.join(set_clauses)} WHERE id = ?"
        cursor.execute(query, values)
        conn.commit()
        return cursor.rowcount > 0
    finally:
        conn.close()

def get_daily_record(user_id: int, record_date: date) -> Optional[Dict]:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "SELECT * FROM daily_records WHERE user_id = ? AND date = ?",
            (user_id, record_date.isoformat())
        )
        row = cursor.fetchone()
        if row:
            return dict(row)
        return None
    finally:
        conn.close()

def get_recent_daily_records(user_id: int, days: int = 7) -> List[Dict]:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            """SELECT * FROM daily_records 
               WHERE user_id = ? 
               ORDER BY date DESC 
               LIMIT ?""",
            (user_id, days)
        )
        return [dict(row) for row in cursor.fetchall()]
    finally:
        conn.close()

def add_time_log(user_id: int, daily_record_id: int, real_timestamp: datetime,
                 activity_type: str, speed_multiplier: float = 1.0,
                 duration_seconds: int = 0, app_name: str = None,
                 virtual_timestamp: datetime = None, virtual_time_display: str = None,
                 notes: str = None) -> int:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            """INSERT INTO time_logs 
               (user_id, daily_record_id, real_timestamp, virtual_timestamp, 
                virtual_time_display, activity_type, speed_multiplier, 
                duration_seconds, app_name, notes)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (user_id, daily_record_id, real_timestamp, virtual_timestamp,
             virtual_time_display, activity_type, speed_multiplier,
             duration_seconds, app_name, notes)
        )
        conn.commit()
        return cursor.lastrowid
    finally:
        conn.close()

def get_time_logs(user_id: int, record_date: date) -> List[Dict]:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            """SELECT tl.* FROM time_logs tl
               JOIN daily_records dr ON tl.daily_record_id = dr.id
               WHERE tl.user_id = ? AND dr.date = ?
               ORDER BY tl.real_timestamp""",
            (user_id, record_date.isoformat())
        )
        return [dict(row) for row in cursor.fetchall()]
    finally:
        conn.close()

def add_pomodoro_session(user_id: int, daily_record_id: int,
                         start_time: datetime, planned_duration: int,
                         session_type: str = 'work',
                         virtual_start_time: datetime = None) -> int:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            """INSERT INTO pomodoro_sessions 
               (user_id, daily_record_id, start_time, planned_duration_minutes,
                session_type, virtual_start_time)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (user_id, daily_record_id, start_time, planned_duration,
             session_type, virtual_start_time)
        )
        conn.commit()
        return cursor.lastrowid
    finally:
        conn.close()

def update_pomodoro_session(session_id: int, **kwargs) -> bool:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        set_clauses = []
        values = []
        for key, value in kwargs.items():
            set_clauses.append(f"{key} = ?")
            values.append(value)
        
        if not set_clauses:
            return False
        
        values.append(session_id)
        query = f"UPDATE pomodoro_sessions SET {', '.join(set_clauses)} WHERE id = ?"
        cursor.execute(query, values)
        conn.commit()
        return cursor.rowcount > 0
    finally:
        conn.close()

def get_pomodoro_sessions(user_id: int, record_date: date) -> List[Dict]:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            """SELECT ps.* FROM pomodoro_sessions ps
               JOIN daily_records dr ON ps.daily_record_id = dr.id
               WHERE ps.user_id = ? AND dr.date = ?
               ORDER BY ps.start_time""",
            (user_id, record_date.isoformat())
        )
        return [dict(row) for row in cursor.fetchall()]
    finally:
        conn.close()

def add_ai_summary(user_id: int, summary_type: str, period_start: date,
                   period_end: date, summary_text: str, source_data: Dict = None) -> int:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            """INSERT INTO ai_summaries 
               (user_id, summary_type, period_start, period_end, summary_text, source_data)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (user_id, summary_type, period_start.isoformat(), period_end.isoformat(),
             summary_text, json.dumps(source_data) if source_data else None)
        )
        conn.commit()
        return cursor.lastrowid
    finally:
        conn.close()

def get_ai_summaries(user_id: int, summary_type: str = None, limit: int = 10) -> List[Dict]:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        if summary_type:
            cursor.execute(
                """SELECT * FROM ai_summaries 
                   WHERE user_id = ? AND summary_type = ?
                   ORDER BY created_at DESC LIMIT ?""",
                (user_id, summary_type, limit)
            )
        else:
            cursor.execute(
                """SELECT * FROM ai_summaries 
                   WHERE user_id = ?
                   ORDER BY created_at DESC LIMIT ?""",
                (user_id, limit)
            )
        return [dict(row) for row in cursor.fetchall()]
    finally:
        conn.close()

def register_device(user_id: int, device_id: str, device_name: str = None,
                    device_type: str = None) -> bool:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            """INSERT INTO devices (user_id, device_id, device_name, device_type, last_active)
               VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
               ON CONFLICT(user_id, device_id) 
               DO UPDATE SET last_active = CURRENT_TIMESTAMP""",
            (user_id, device_id, device_name, device_type)
        )
        conn.commit()
        return True
    finally:
        conn.close()

def get_user_devices(user_id: int) -> List[Dict]:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "SELECT * FROM devices WHERE user_id = ? ORDER BY last_active DESC",
            (user_id,)
        )
        return [dict(row) for row in cursor.fetchall()]
    finally:
        conn.close()

def add_app_usage_log(user_id: int, device_id: str, app_package: str,
                      start_time: datetime, activity_type: str,
                      app_name: str = None, end_time: datetime = None,
                      duration_seconds: int = 0) -> int:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            """INSERT INTO app_usage_logs 
               (user_id, device_id, app_package, app_name, start_time, end_time,
                duration_seconds, activity_type)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (user_id, device_id, app_package, app_name, start_time, end_time,
             duration_seconds, activity_type)
        )
        conn.commit()
        return cursor.lastrowid
    finally:
        conn.close()

def get_app_usage_logs(user_id: int, record_date: date) -> List[Dict]:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            """SELECT * FROM app_usage_logs 
               WHERE user_id = ? AND DATE(start_time) = ?
               ORDER BY start_time""",
            (user_id, record_date.isoformat())
        )
        return [dict(row) for row in cursor.fetchall()]
    finally:
        conn.close()

def get_yesterday_sleep_time(user_id: int) -> Optional[datetime]:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            """SELECT real_sleep_time FROM daily_records 
               WHERE user_id = ? AND real_sleep_time IS NOT NULL
               ORDER BY date DESC LIMIT 1""",
            (user_id,)
        )
        row = cursor.fetchone()
        if row and row['real_sleep_time']:
            return datetime.fromisoformat(row['real_sleep_time'])
        return None
    finally:
        conn.close()

def get_yesterday_virtual_sleep_time(user_id: int) -> Optional[datetime]:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            """SELECT virtual_sleep_time FROM daily_records 
               WHERE user_id = ? AND virtual_sleep_time IS NOT NULL
               ORDER BY date DESC LIMIT 1""",
            (user_id,)
        )
        row = cursor.fetchone()
        if row and row['virtual_sleep_time']:
            return datetime.fromisoformat(row['virtual_sleep_time'])
        return None
    finally:
        conn.close()

init_database()
