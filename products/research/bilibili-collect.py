#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
B 站 UP 主视频采集脚本
用途：采集指定 UP 主一年内的视频数据
输出：CSV 文件 + 基础统计
"""

import requests
import time
import csv
from datetime import datetime, timedelta
from pathlib import Path

# ============= 配置区域 =============
# UP 主 UID（在 B 站个人主页 URL 中获取）
UP_UID = "12345678"  # 替换为目标 UP 主 UID

# 时间范围
END_DATE = datetime.now()  # 截止日期（今天）
START_DATE = END_DATE - timedelta(days=365)  # 开始日期（一年前）

# 输出文件
OUTPUT_DIR = Path("bilibili_data")
OUTPUT_DIR.mkdir(exist_ok=True)

# 请求头（模拟浏览器）
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Referer": "https://www.bilibili.com/"
}

# ============= API 函数 =============

def get_up_info(uid):
    """获取 UP 主基本信息"""
    url = "https://api.bilibili.com/x/space/acc/info"
    params = {"mid": uid}
    resp = requests.get(url, headers=HEADERS, params=params, timeout=10)
    resp.raise_for_status()
    data = resp.json()
    if data["code"] == 0:
        return data["data"]
    return None

def get_video_list(uid, page=1, page_size=30):
    """获取视频列表"""
    url = "https://api.bilibili.com/x/space/arc/search"
    params = {
        "mid": uid,
        "pn": page,
        "ps": page_size,
        "order": "pubdate",  # 按发布时间排序
        "keyword": "",
        "tid": 0
    }
    resp = requests.get(url, headers=HEADERS, params=params, timeout=10)
    resp.raise_for_status()
    data = resp.json()
    if data["code"] == 0:
        return data["data"]
    return None

def get_video_stats(bvid):
    """获取视频详细统计（硬币、收藏等）"""
    url = "https://api.bilibili.com/x/web-interface/archive/stat"
    params = {"bvid": bvid}
    resp = requests.get(url, headers=HEADERS, params=params, timeout=10)
    resp.raise_for_status()
    data = resp.json()
    if data["code"] == 0:
        return data["data"]
    return None

# ============= 数据处理 =============

def filter_by_date(videos, start_date, end_date):
    """按日期过滤视频"""
    filtered = []
    for video in videos:
        pubdate = datetime.fromtimestamp(video["pubdate"])
        if start_date <= pubdate <= end_date:
            video["pubdate_datetime"] = pubdate
            filtered.append(video)
    return filtered

def save_to_csv(videos, filename):
    """保存视频数据到 CSV"""
    if not videos:
        print("⚠️ 没有数据可保存")
        return
    
    fieldnames = [
        "bvid", "aid", "title", "pubdate", "duration",
        "play", "danmaku", "like", "coin", "favorite", "share",
        "tname", "length"
    ]
    
    with open(filename, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for video in videos:
            writer.writerow({
                "bvid": video.get("bvid", ""),
                "aid": video.get("aid", ""),
                "title": video.get("title", ""),
                "pubdate": datetime.fromtimestamp(video.get("pubdate", 0)).strftime("%Y-%m-%d %H:%M"),
                "duration": video.get("duration", ""),
                "play": video.get("stat", {}).get("view", 0),
                "danmaku": video.get("stat", {}).get("danmaku", 0),
                "like": video.get("stat", {}).get("like", 0),
                "coin": video.get("stat", {}).get("coin", 0),
                "favorite": video.get("stat", {}).get("favorite", 0),
                "share": video.get("stat", {}).get("share", 0),
                "tname": video.get("tname", ""),
                "length": video.get("length", "")
            })
    print(f"✅ 已保存 {len(videos)} 条数据到 {filename}")

# ============= 主流程 =============

def main():
    print("=" * 60)
    print("B 站 UP 主视频采集脚本")
    print("=" * 60)
    print(f"UP 主 UID: {UP_UID}")
    print(f"时间范围：{START_DATE.strftime('%Y-%m-%d')} 至 {END_DATE.strftime('%Y-%m-%d')}")
    print()
    
    # 1. 获取 UP 主信息
    print("📥 获取 UP 主信息...")
    up_info = get_up_info(UP_UID)
    if up_info:
        print(f"UP 主：{up_info['name']}")
        print(f"粉丝数：{up_info['follower']}")
        print(f"签名：{up_info['sign']}")
    else:
        print("❌ 获取 UP 主信息失败")
        return
    print()
    
    # 2. 获取视频列表
    print("📥 获取视频列表...")
    all_videos = []
    page = 1
    total_pages = 999
    
    while page <= total_pages:
        data = get_video_list(UP_UID, page=page)
        if not data:
            print(f"❌ 获取第{page}页失败")
            break
        
        videos = data.get("list", {}).get("vlist", [])
        if not videos:
            break
        
        all_videos.extend(videos)
        total_pages = min(data["page"]["count"], 10)  # 限制最多 10 页（300 个视频）
        
        print(f"  第{page}/{total_pages}页，获取{len(videos)}个视频")
        page += 1
        time.sleep(0.5)  # 避免请求过快
    
    print(f"✅ 共获取 {len(all_videos)} 个视频")
    print()
    
    # 3. 按日期过滤
    print("📅 按日期过滤...")
    filtered_videos = filter_by_date(all_videos, START_DATE, END_DATE)
    print(f"✅ 符合条件的视频：{len(filtered_videos)} 个")
    print()
    
    # 4. 获取详细统计（可选，耗时较长）
    print("📥 获取详细统计数据...")
    for video in filtered_videos[:20]:  # 限制前 20 个，避免 API 调用过多
        stats = get_video_stats(video["bvid"])
        if stats:
            video["stat"] = stats
        time.sleep(0.3)
    print("✅ 详细统计获取完成")
    print()
    
    # 5. 保存数据
    output_file = OUTPUT_DIR / f"{up_info['name']}_videos_{START_DATE.strftime('%Y%m%d')}_{END_DATE.strftime('%Y%m%d')}.csv"
    save_to_csv(filtered_videos, output_file)
    
    # 6. 基础统计
    print()
    print("=" * 60)
    print("📊 基础统计")
    print("=" * 60)
    if filtered_videos:
        total_play = sum(v.get("stat", {}).get("view", v.get("play", 0)) for v in filtered_videos)
        total_like = sum(v.get("stat", {}).get("like", v.get("like", 0)) for v in filtered_videos)
        avg_play = total_play / len(filtered_videos)
        avg_like = total_like / len(filtered_videos)
        
        print(f"视频总数：{len(filtered_videos)}")
        print(f"总播放量：{total_play:,}")
        print(f"总点赞数：{total_like:,}")
        print(f"平均播放：{avg_play:,.0f}")
        print(f"平均点赞：{avg_like:,.0f}")
        print(f"互动率：{(total_like/total_play*100) if total_play > 0 else 0:.2f}%")
    
    print()
    print(f"💾 数据已保存到：{output_file.absolute()}")
    print("=" * 60)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n⚠️ 用户中断")
    except Exception as e:
        print(f"\n❌ 错误：{e}")
        import traceback
        traceback.print_exc()
