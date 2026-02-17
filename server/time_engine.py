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
        
    def initialize_day(self, real_wake_time: datetime, 
                       yesterday_sleep: datetime = None,
                       yesterday_virtual_sleep: datetime = None):
        target_wake = self.time_config['target_wake_time']
        approach_rate = self.time_config['time_approach_rate']
        virtual_wake, virtual_wake_display = calculate_virtual_wake_time(
            real_wake_time, target_wake, approach_rate
        )
        self.virtual_time_offset = virtual_wake - real_wake_time
        self.last_update_time = real_wake_time
        return {
            'virtual_wake_time': virtual_wake,
            'virtual_wake_display': virtual_wake_display,
        }
    
    def update_activity(self, activity_type: str, app_name: str = None,
                        entertainment_apps: list = None, study_apps: list = None):
        self.current_activity = activity_type
        if activity_type == 'entertainment':
            self.current_speed = getattr(self, 'entertainment_multiplier', 2.0)
        elif activity_type == 'study':
            self.current_speed = self._calculate_study_speed()
        else:
            self.current_speed = self.time_config['rest_speed']
        return self.current_speed
    
    def start_study_session(self, planned_duration_minutes: int):
        self.study_start_time = datetime.now()
        self.study_planned_duration = planned_duration_minutes * 60
        self.current_activity = 'study'
        
    def _calculate_study_speed(self) -> float:
        if self.study_start_time is None or self.study_planned_duration <= 0:
            return self.time_config['study_end_speed']
        elapsed = (datetime.now() - self.study_start_time).total_seconds()
        if elapsed >= self.study_planned_duration:
            return self.time_config['study_end_speed']
        progress = elapsed / self.study_planned_duration
        start_speed = self.time_config['study_start_speed']
        end_speed = self.time_config['study_end_speed']
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