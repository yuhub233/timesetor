import requests
import json
from datetime import datetime, date, timedelta
from typing import Dict, List, Optional
import os
import yaml

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "config.yaml")

def load_config():
    with open(CONFIG_PATH, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)

class AIService:
    def __init__(self, config_override: Dict = None):
        self.config = config_override or load_config()
        self.ai_config = self.config.get('ai', {})
        
    def is_enabled(self) -> bool:
        return self.ai_config.get('enabled', False) and bool(self.ai_config.get('api_url'))
    
    def _call_api(self, messages: List[Dict], max_tokens: int = 1000) -> Optional[str]:
        if not self.is_enabled():
            return None
        
        try:
            headers = {
                'Content-Type': 'application/json',
                'Authorization': f"Bearer {self.ai_config.get('api_key', '')}"
            }
            
            payload = {
                'model': self.ai_config.get('model', 'gpt-3.5-turbo'),
                'messages': messages,
                'max_tokens': max_tokens,
                'temperature': 0.7
            }
            
            response = requests.post(
                self.ai_config['api_url'],
                headers=headers,
                json=payload,
                timeout=60
            )
            
            if response.status_code == 200:
                result = response.json()
                return result['choices'][0]['message']['content']
            else:
                print(f"AI API error: {response.status_code} - {response.text}")
                return None
        except Exception as e:
            print(f"AI API call failed: {e}")
            return None
    
    def generate_daily_summary(self, daily_data: Dict) -> Optional[str]:
        if not self.is_enabled():
            return None
        
        prompt = self.ai_config.get('daily_summary_prompt', '请根据以下数据生成一份简洁的每日总结：')
        
        data_summary = self._format_daily_data(daily_data)
        
        messages = [
            {'role': 'system', 'content': '你是一个时间管理助手，帮助用户分析他们的时间使用情况并提供有益的建议。'},
            {'role': 'user', 'content': f"{prompt}\n\n{data_summary}"}
        ]
        
        return self._call_api(messages, max_tokens=500)
    
    def generate_weekly_summary(self, weekly_data: List[Dict]) -> Optional[str]:
        if not self.is_enabled():
            return None
        
        prompt = self.ai_config.get('weekly_summary_prompt', '请根据以下周数据生成周总结：')
        
        data_summary = self._format_weekly_data(weekly_data)
        
        messages = [
            {'role': 'system', 'content': '你是一个时间管理助手，帮助用户分析他们的周时间使用情况，发现规律并提供改进建议。'},
            {'role': 'user', 'content': f"{prompt}\n\n{data_summary}"}
        ]
        
        return self._call_api(messages, max_tokens=800)
    
    def generate_monthly_summary(self, monthly_data: List[Dict]) -> Optional[str]:
        if not self.is_enabled():
            return None
        
        prompt = self.ai_config.get('monthly_summary_prompt', '请根据以下月数据生成月总结：')
        
        data_summary = self._format_monthly_data(monthly_data)
        
        messages = [
            {'role': 'system', 'content': '你是一个时间管理助手，帮助用户分析他们的月度时间使用情况，发现长期趋势并提供战略性建议。'},
            {'role': 'user', 'content': f"{prompt}\n\n{data_summary}"}
        ]
        
        return self._call_api(messages, max_tokens=1000)
    
    def generate_yearly_summary(self, yearly_data: List[Dict]) -> Optional[str]:
        if not self.is_enabled():
            return None
        
        prompt = self.ai_config.get('yearly_summary_prompt', '请根据以下年数据生成年总结：')
        
        data_summary = self._format_yearly_data(yearly_data)
        
        messages = [
            {'role': 'system', 'content': '你是一个时间管理助手，帮助用户分析他们的年度时间使用情况，回顾成就并展望未来。'},
            {'role': 'user', 'content': f"{prompt}\n\n{data_summary}"}
        ]
        
        return self._call_api(messages, max_tokens=1500)
    
    def _format_daily_data(self, data: Dict) -> str:
        lines = [f"日期: {data.get('date', '未知')}"]
        
        if data.get('real_wake_time'):
            lines.append(f"实际起床时间: {data['real_wake_time']}")
        if data.get('real_sleep_time'):
            lines.append(f"实际睡觉时间: {data['real_sleep_time']}")
        if data.get('virtual_wake_time_display'):
            lines.append(f"不常规起床时间: {data['virtual_wake_time_display']}")
        
        lines.append(f"目标娱乐时长: {data.get('target_entertainment_hours', 0)}小时")
        lines.append(f"目标学习时长: {data.get('target_study_hours', 0)}小时")
        
        lines.append(f"实际娱乐时长: {data.get('actual_entertainment_minutes', 0)}分钟")
        lines.append(f"实际学习时长: {data.get('actual_study_minutes', 0)}分钟")
        lines.append(f"实际休息时长: {data.get('actual_rest_minutes', 0)}分钟")
        
        lines.append(f"不常规娱乐时长: {data.get('virtual_entertainment_minutes', 0)}分钟")
        lines.append(f"不常规学习时长: {data.get('virtual_study_minutes', 0)}分钟")
        
        if data.get('pomodoro_count'):
            lines.append(f"番茄钟次数: {data['pomodoro_count']}")
        
        return '\n'.join(lines)
    
    def _format_weekly_data(self, data: List[Dict]) -> str:
        lines = ["本周数据汇总:"]
        
        total_entertainment = 0
        total_study = 0
        total_rest = 0
        total_pomodoro = 0
        valid_days = 0
        
        for day in data:
            total_entertainment += day.get('actual_entertainment_minutes', 0)
            total_study += day.get('actual_study_minutes', 0)
            total_rest += day.get('actual_rest_minutes', 0)
            total_pomodoro += day.get('pomodoro_count', 0)
            if day.get('real_wake_time'):
                valid_days += 1
        
        lines.append(f"有效记录天数: {valid_days}")
        lines.append(f"总娱乐时长: {total_entertainment / 60:.1f}小时")
        lines.append(f"总学习时长: {total_study / 60:.1f}小时")
        lines.append(f"总休息时长: {total_rest / 60:.1f}小时")
        lines.append(f"总番茄钟次数: {total_pomodoro}")
        
        if valid_days > 0:
            lines.append(f"日均娱乐: {total_entertainment / valid_days:.0f}分钟")
            lines.append(f"日均学习: {total_study / valid_days:.0f}分钟")
        
        return '\n'.join(lines)
    
    def _format_monthly_data(self, data: List[Dict]) -> str:
        lines = ["本月数据汇总:"]
        
        total_entertainment = 0
        total_study = 0
        total_rest = 0
        total_pomodoro = 0
        valid_days = 0
        
        for week in data:
            total_entertainment += week.get('total_entertainment_minutes', 0)
            total_study += week.get('total_study_minutes', 0)
            total_rest += week.get('total_rest_minutes', 0)
            total_pomodoro += week.get('total_pomodoro', 0)
            valid_days += week.get('valid_days', 0)
        
        lines.append(f"有效记录天数: {valid_days}")
        lines.append(f"总娱乐时长: {total_entertainment / 60:.1f}小时")
        lines.append(f"总学习时长: {total_study / 60:.1f}小时")
        lines.append(f"总休息时长: {total_rest / 60:.1f}小时")
        lines.append(f"总番茄钟次数: {total_pomodoro}")
        
        return '\n'.join(lines)
    
    def _format_yearly_data(self, data: List[Dict]) -> str:
        lines = ["本年数据汇总:"]
        
        total_entertainment = 0
        total_study = 0
        total_rest = 0
        total_pomodoro = 0
        valid_days = 0
        
        for month in data:
            total_entertainment += month.get('total_entertainment_minutes', 0)
            total_study += month.get('total_study_minutes', 0)
            total_rest += month.get('total_rest_minutes', 0)
            total_pomodoro += month.get('total_pomodoro', 0)
            valid_days += month.get('valid_days', 0)
        
        lines.append(f"有效记录天数: {valid_days}")
        lines.append(f"总娱乐时长: {total_entertainment / 60:.1f}小时")
        lines.append(f"总学习时长: {total_study / 60:.1f}小时")
        lines.append(f"总休息时长: {total_rest / 60:.1f}小时")
        lines.append(f"总番茄钟次数: {total_pomodoro}")
        
        if valid_days > 0:
            lines.append(f"日均娱乐: {total_entertainment / valid_days:.0f}分钟")
            lines.append(f"日均学习: {total_study / valid_days:.0f}分钟")
        
        return '\n'.join(lines)

def should_generate_summary(summary_type: str, current_date: date) -> bool:
    if summary_type == 'daily':
        return True
    elif summary_type == 'weekly':
        return current_date.weekday() == 6
    elif summary_type == 'monthly':
        return current_date.day == 1 or is_last_day_of_month(current_date)
    elif summary_type == 'yearly':
        return current_date.month == 12 and current_date.day == 31
    return False

def is_last_day_of_month(check_date: date) -> bool:
    next_day = check_date + timedelta(days=1)
    return next_day.month != check_date.month
