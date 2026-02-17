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