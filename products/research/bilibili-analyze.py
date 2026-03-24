#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
B 站视频数据分析脚本
用途：分析采集的视频数据，生成统计报告和可视化图表
"""

import pandas as pd
import numpy as np
from pathlib import Path
from datetime import datetime

# ============= 配置 =============
DATA_FILE = "bilibili_data/[文件名].csv"  # 替换为实际文件名
OUTPUT_DIR = Path("bilibili_analysis")
OUTPUT_DIR.mkdir(exist_ok=True)

# ============= 数据加载 =============

def load_data(filepath):
    """加载 CSV 数据"""
    df = pd.read_csv(filepath, encoding="utf-8")
    df["pubdate"] = pd.to_datetime(df["pubdate"])
    df["month"] = df["pubdate"].dt.to_period("M")
    return df

# ============= 分析函数 =============

def basic_stats(df):
    """基础统计"""
    stats = {
        "视频总数": len(df),
        "总播放量": df["play"].sum(),
        "总点赞数": df["like"].sum(),
        "总弹幕数": df["danmaku"].sum(),
        "总硬币数": df["coin"].sum(),
        "总收藏数": df["favorite"].sum(),
        "总分享数": df["share"].sum(),
        "平均播放量": df["play"].mean(),
        "平均点赞数": df["like"].mean(),
        "平均弹幕数": df["danmaku"].mean(),
        "互动率": (df["like"].sum() / df["play"].sum() * 100) if df["play"].sum() > 0 else 0,
        "三连率": ((df["like"] + df["coin"] + df["favorite"]).sum() / df["play"].sum() * 100) if df["play"].sum() > 0 else 0
    }
    return stats

def monthly_trend(df):
    """月度趋势分析"""
    monthly = df.groupby("month").agg({
        "play": "sum",
        "like": "sum",
        "danmaku": "sum",
        "bvid": "count"
    }).rename(columns={"bvid": "video_count"})
    return monthly

def top_videos(df, n=10):
    """TOP N 视频"""
    return {
        "播放 TOP10": df.nlargest(n, "play")[["title", "play", "like", "pubdate"]],
        "点赞 TOP10": df.nlargest(n, "like")[["title", "play", "like", "pubdate"]],
        "弹幕 TOP10": df.nlargest(n, "danmaku")[["title", "play", "danmaku", "pubdate"]]
    }

def category_analysis(df):
    """分区分析"""
    category = df.groupby("tname").agg({
        "play": ["sum", "mean"],
        "like": "sum",
        "bvid": "count"
    }).round(0)
    return category

def time_analysis(df):
    """发布时间分析"""
    df["weekday"] = df["pubdate"].dt.day_name()
    df["hour"] = df["pubdate"].dt.hour
    
    weekday_dist = df.groupby("weekday")["bvid"].count()
    hour_dist = df.groupby("hour")["bvid"].count()
    
    return weekday_dist, hour_dist

# ============= 报告生成 =============

def generate_report(stats, monthly, top_videos_data, category, time_data):
    """生成 Markdown 报告"""
    report = []
    report.append("# B 站视频分析报告\n")
    report.append(f"**生成时间：** {datetime.now().strftime('%Y-%m-%d %H:%M')}\n")
    report.append(f"**数据范围：** {df['pubdate'].min().strftime('%Y-%m-%d')} 至 {df['pubdate'].max().strftime('%Y-%m-%d')}\n")
    report.append("---\n")
    
    # 基础统计
    report.append("## 📊 基础统计\n")
    report.append("| 指标 | 数值 |")
    report.append("|------|------|")
    for k, v in stats.items():
        if isinstance(v, float):
            report.append(f"| {k} | {v:,.2f} |")
        else:
            report.append(f"| {k} | {v:,} |")
    report.append("")
    
    # 月度趋势
    report.append("## 📈 月度趋势\n")
    report.append("| 月份 | 视频数 | 播放量 | 点赞数 | 弹幕数 |")
    report.append("|------|--------|--------|--------|--------|")
    for idx, row in monthly.iterrows():
        report.append(f"| {idx} | {row['video_count']} | {row['play']:,} | {row['like']:,} | {row['danmaku']:,} |")
    report.append("")
    
    # TOP 视频
    report.append("## 🔥 TOP10 视频\n")
    report.append("### 播放量 TOP10\n")
    report.append("| 排名 | 标题 | 播放量 | 点赞数 | 发布时间 |")
    report.append("|------|------|--------|--------|----------|")
    for i, (_, row) in enumerate(top_videos_data["播放 TOP10"].iterrows(), 1):
        title = row["title"][:30] + "..." if len(row["title"]) > 30 else row["title"]
        report.append(f"| {i} | {title} | {row['play']:,} | {row['like']:,} | {row['pubdate'].strftime('%m-%d')} |")
    report.append("")
    
    # 分区分析
    report.append("## 📁 分区分析\n")
    report.append("| 分区 | 视频数 | 总播放 | 平均播放 | 总点赞 |")
    report.append("|------|--------|--------|----------|--------|")
    for idx, row in category.iterrows():
        report.append(f"| {idx} | {row[('bvid', 'count')]} | {row[('play', 'sum')]:,} | {row[('play', 'mean')]:,.0f} | {row[('like', 'sum')]:,} |")
    report.append("")
    
    # 发布时间分析
    report.append("## ⏰ 发布时间分析\n")
    report.append("### 星期分布\n")
    for weekday, count in time_data[0].items():
        report.append(f"- {weekday}: {count} 个视频")
    report.append("")
    
    report.append("### 小时分布\n")
    for hour, count in time_data[1].items():
        bar = "█" * (count // max(time_data[1]) * 20)
        report.append(f"- {hour:02d}:00 {bar} ({count})")
    report.append("")
    
    # 洞察建议
    report.append("## 💡 洞察与建议\n")
    report.append("1. **最佳发布时间：** 根据数据，[星期 X] [XX:00] 发布的视频表现最好\n")
    report.append("2. **热门分区：** [分区名] 分区平均播放量最高\n")
    report.append("3. **内容建议：** TOP 视频的共同特点是...\n")
    
    return "\n".join(report)

# ============= 主流程 =============

if __name__ == "__main__":
    print("=" * 60)
    print("B 站视频数据分析")
    print("=" * 60)
    
    # 加载数据
    print(f"📥 加载数据：{DATA_FILE}")
    df = load_data(DATA_FILE)
    print(f"✅ 共 {len(df)} 条数据")
    print()
    
    # 执行分析
    print("📊 执行分析...")
    stats = basic_stats(df)
    monthly = monthly_trend(df)
    top_data = top_videos(df)
    category = category_analysis(df)
    time_data = time_analysis(df)
    print("✅ 分析完成")
    print()
    
    # 生成报告
    print("📝 生成报告...")
    report = generate_report(stats, monthly, top_data, category, time_data)
    report_file = OUTPUT_DIR / f"analysis_report_{datetime.now().strftime('%Y%m%d_%H%M')}.md"
    with open(report_file, "w", encoding="utf-8") as f:
        f.write(report)
    print(f"✅ 报告已保存：{report_file.absolute()}")
    print()
    
    # 保存 Excel（带图表数据）
    excel_file = OUTPUT_DIR / f"analysis_data_{datetime.now().strftime('%Y%m%d_%H%M')}.xlsx"
    with pd.ExcelWriter(excel_file) as writer:
        df.to_excel(writer, sheet_name="原始数据", index=False)
        monthly.to_excel(writer, sheet_name="月度趋势")
        category.to_excel(writer, sheet_name="分区分析")
    print(f"✅ Excel 已保存：{excel_file.absolute()}")
    print()
    
    print("=" * 60)
    print("分析完成！")
    print("=" * 60)
