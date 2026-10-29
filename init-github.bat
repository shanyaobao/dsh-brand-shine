@echo off
chcp 65001 >nul
echo ==============================================
echo dsh-brand-shine GitHub仓库初始化脚本
echo 使用前请先手动操作1步：
echo 打开 https://github.com/new 登录你的账号shanyaobao
echo 1. Repository name填：dsh-brand-shine
echo 2. 选Public（公开仓库，否则无法被插件市场收录）
echo 3. 不要勾选Add a README file/.gitignore/LICENSE
echo 4. 点Create repository创建完成后，回到这里按任意键继续
echo ==============================================
pause

echo 正在初始化本地git仓库...
git init
git add .
git commit -m "feat: 首次发布 dsh-brand-shine v0.1.0 品牌替换插件"
git branch -M main
git remote add origin https://github.com/shanyaobao/dsh-brand-shine.git
echo 正在推送代码到GitHub...
git push -u origin main

echo ==============================================
echo ✅ 代码推送完成！
echo 接下来手动做2步：
echo 1. 打开仓库页面 → 点齿轮图标About →  Topics里填dsh-plugin，保存
echo 2. 回到插件目录执行npm publish发布到npm（如果没登录先npm login）
echo ==============================================
pause
