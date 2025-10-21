#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Redis 哨兵模式 Web 应用
使用 Flask 框架
"""

from flask import Flask, request, jsonify
import json
import time
from redis_config import get_redis_master, get_redis_slave, get_redis_info

app = Flask(__name__)

# 统一响应格式
def success_response(data=None):
    """成功响应"""
    return jsonify({
        'code': 200,
        'message': 'success',
        'data': data
    })

def error_response(code, message):
    """错误响应"""
    return jsonify({
        'code': code,
        'message': message
    }), code

@app.route('/api/v1/kv', methods=['POST'])
def set_key_value():
    """设置键值对"""
    try:
        data = request.get_json()
        key = data.get('key')
        value = data.get('value')
        ttl = data.get('ttl', 0)
        
        if not key or not value:
            return error_response(400, '键名和值不能为空')
        
        master = get_redis_master()
        
        if ttl > 0:
            master.setex(key, ttl, value)
        else:
            master.set(key, value)
        
        return success_response({
            'key': key,
            'value': value,
            'ttl': ttl
        })
        
    except Exception as e:
        return error_response(500, f'设置失败: {str(e)}')

@app.route('/api/v1/kv/<key>', methods=['GET'])
def get_key_value(key):
    """获取键值对"""
    try:
        slave = get_redis_slave()
        value = slave.get(key)
        
        if value is None:
            return error_response(404, '键不存在')
        
        return success_response({
            'key': key,
            'value': value
        })
        
    except Exception as e:
        return error_response(500, f'获取失败: {str(e)}')

@app.route('/api/v1/kv/<key>', methods=['DELETE'])
def delete_key(key):
    """删除键"""
    try:
        master = get_redis_master()
        count = master.delete(key)
        
        return success_response({
            'key': key,
            'count': count
        })
        
    except Exception as e:
        return error_response(500, f'删除失败: {str(e)}')

@app.route('/api/v1/kv/<key>/exists', methods=['GET'])
def exists_key(key):
    """检查键是否存在"""
    try:
        slave = get_redis_slave()
        exists = slave.exists(key)
        
        return success_response({
            'key': key,
            'exists': bool(exists)
        })
        
    except Exception as e:
        return error_response(500, f'检查失败: {str(e)}')

@app.route('/api/v1/users', methods=['POST'])
def set_user():
    """设置用户信息"""
    try:
        data = request.get_json()
        user_id = data.get('id')
        name = data.get('name')
        age = data.get('age')
        
        if not all([user_id, name, age]):
            return error_response(400, '用户ID、姓名和年龄不能为空')
        
        master = get_redis_master()
        user_key = f'user:{user_id}'
        
        user_data = {
            'id': user_id,
            'name': name,
            'age': age
        }
        
        master.hset(user_key, mapping=user_data)
        
        return success_response({
            'user': user_data
        })
        
    except Exception as e:
        return error_response(500, f'设置用户失败: {str(e)}')

@app.route('/api/v1/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    """获取用户信息"""
    try:
        slave = get_redis_slave()
        user_key = f'user:{user_id}'
        user_data = slave.hgetall(user_key)
        
        if not user_data:
            return error_response(404, '用户不存在')
        
        # 转换数据类型
        user_data['id'] = int(user_data['id'])
        user_data['age'] = int(user_data['age'])
        
        return success_response({
            'user': user_data
        })
        
    except Exception as e:
        return error_response(500, f'获取用户失败: {str(e)}')

@app.route('/api/v1/lists', methods=['POST'])
def add_list_item():
    """添加列表项"""
    try:
        data = request.get_json()
        list_key = data.get('list_key')
        items = data.get('items', [])
        
        if not list_key or not items:
            return error_response(400, '列表键名和项目不能为空')
        
        master = get_redis_master()
        count = master.lpush(list_key, *items)
        
        return success_response({
            'list_key': list_key,
            'count': count,
            'items': items
        })
        
    except Exception as e:
        return error_response(500, f'添加列表项失败: {str(e)}')

@app.route('/api/v1/lists/<list_key>', methods=['GET'])
def get_list(list_key):
    """获取列表"""
    try:
        slave = get_redis_slave()
        items = slave.lrange(list_key, 0, -1)
        
        return success_response({
            'list_key': list_key,
            'items': items,
            'count': len(items)
        })
        
    except Exception as e:
        return error_response(500, f'获取列表失败: {str(e)}')

@app.route('/api/v1/lists/<list_key>/pop', methods=['DELETE'])
def pop_list_item(list_key):
    """弹出列表项"""
    try:
        master = get_redis_master()
        item = master.rpop(list_key)
        
        if item is None:
            return error_response(404, '列表为空')
        
        return success_response({
            'list_key': list_key,
            'item': item
        })
        
    except Exception as e:
        return error_response(500, f'弹出列表项失败: {str(e)}')

@app.route('/api/v1/sets', methods=['POST'])
def add_set_member():
    """添加集合成员"""
    try:
        data = request.get_json()
        set_key = data.get('set_key')
        members = data.get('members', [])
        
        if not set_key or not members:
            return error_response(400, '集合键名和成员不能为空')
        
        master = get_redis_master()
        count = master.sadd(set_key, *members)
        
        return success_response({
            'set_key': set_key,
            'count': count,
            'members': members
        })
        
    except Exception as e:
        return error_response(500, f'添加集合成员失败: {str(e)}')

@app.route('/api/v1/sets/<set_key>', methods=['GET'])
def get_set_members(set_key):
    """获取集合成员"""
    try:
        slave = get_redis_slave()
        members = list(slave.smembers(set_key))
        
        return success_response({
            'set_key': set_key,
            'members': members,
            'count': len(members)
        })
        
    except Exception as e:
        return error_response(500, f'获取集合成员失败: {str(e)}')

@app.route('/api/v1/redis/status', methods=['GET'])
def get_redis_status():
    """获取 Redis 状态"""
    try:
        info = get_redis_info()
        
        if not info:
            return error_response(500, '获取 Redis 状态失败')
        
        return success_response({
            'master_addr': info['master'],
            'slave_addrs': info['slaves'],
            'sentinel_info': info['sentinels']
        })
        
    except Exception as e:
        return error_response(500, f'获取 Redis 状态失败: {str(e)}')

@app.route('/api/v1/health', methods=['GET'])
def health_check():
    """健康检查"""
    try:
        master = get_redis_master()
        slave = get_redis_slave()
        
        # 测试主节点连接
        master.ping()
        
        # 测试从节点连接
        slave.ping()
        
        return success_response({
            'status': 'healthy',
            'timestamp': int(time.time())
        })
        
    except Exception as e:
        return error_response(503, f'健康检查失败: {str(e)}')

@app.route('/')
def index():
    """首页"""
    return jsonify({
        'message': 'Redis 哨兵模式 Web 应用',
        'version': '1.0.0',
        'endpoints': [
            'POST /api/v1/kv - 设置键值对',
            'GET /api/v1/kv/:key - 获取键值对',
            'DELETE /api/v1/kv/:key - 删除键',
            'GET /api/v1/kv/:key/exists - 检查键是否存在',
            'POST /api/v1/users - 设置用户',
            'GET /api/v1/users/:id - 获取用户',
            'POST /api/v1/lists - 添加列表项',
            'GET /api/v1/lists/:list_key - 获取列表',
            'DELETE /api/v1/lists/:list_key/pop - 弹出列表项',
            'POST /api/v1/sets - 添加集合成员',
            'GET /api/v1/sets/:set_key - 获取集合成员',
            'GET /api/v1/redis/status - 获取 Redis 状态',
            'GET /api/v1/health - 健康检查'
        ]
    })

if __name__ == '__main__':
    print("Redis 哨兵模式 Web 应用启动中...")
    print("API 文档:")
    print("  POST   /api/v1/kv              - 设置键值对")
    print("  GET    /api/v1/kv/:key         - 获取键值对")
    print("  DELETE /api/v1/kv/:key         - 删除键")
    print("  GET    /api/v1/kv/:key/exists  - 检查键是否存在")
    print("  POST   /api/v1/users           - 设置用户")
    print("  GET    /api/v1/users/:id       - 获取用户")
    print("  POST   /api/v1/lists           - 添加列表项")
    print("  GET    /api/v1/lists/:list_key - 获取列表")
    print("  DELETE /api/v1/lists/:list_key/pop - 弹出列表项")
    print("  POST   /api/v1/sets            - 添加集合成员")
    print("  GET    /api/v1/sets/:set_key   - 获取集合成员")
    print("  GET    /api/v1/redis/status    - 获取 Redis 状态")
    print("  GET    /api/v1/health          - 健康检查")
    
    app.run(host='0.0.0.0', port=8080, debug=True)
