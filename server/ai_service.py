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
            {'role': 'system', 'content': '你是一个时间管理助手，帮助用户分析他们的周时间使用情况。'},
            {'role': 'user', 'content': f"{prompt}\n\n{data_summary}"}
        ]
        return self._call_api(messages, max_tokens=800)
    
    def _format_daily_data(self, data: Dict) -> str:
        lines = [f"日期: {data.get('date', '未知')}"]
        if data.get('real_wake_time'):
            lines.append(f"实际起床时间: {data['real_wake_time']}")
        lines.append(f"实际娱乐时长: {data.get('actual_entertainment_minutes', 0)}分钟")
        lines.append(f"实际学习时长: {data.get('actual_study_minutes', 0)}分钟")
        return '\n'.join(lines)
    
    def _format_weekly_data(self, data: List[Dict]) -> str:
        lines = ["本周数据汇总:"]
        total_entertainment = sum(d.get('actual_entertainment_minutes', 0) for d in data)
        total_study = sum(d.get('actual_study_minutes', 0) for d in data)
        lines.append(f"总娱乐时长: {total_entertainment / 60:.1f}小时")
        lines.append(f"总学习时长: {total_study / 60:.1f}小时")
        return '\n'.join(lines)