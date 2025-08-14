#!/usr/bin/env bash

# 设置定量 | Quantities
## 仓库目录 | Repository directory
REPO_DIR="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)"
TEST_DIR="$REPO_DIR/target/test"

# 清理之前的测试环境 | Clean up previous test environment
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

# 测试函数 | Test functions
test_cleanup() {
  echo "=== 测试清理功能 ==="
  
  # 创建测试回收站目录 | Create test trash directories
  TRASH_DIR="$TEST_DIR/trash"
  FILES_DIR="$TRASH_DIR/files"
  INFO_DIR="$TRASH_DIR/info"
  EXPUNGED_DIR="$TRASH_DIR/expunged"
  
  mkdir -p "$FILES_DIR" "$INFO_DIR" "$EXPUNGED_DIR"
  
  # 计算测试日期 | Calculate test dates
  # 旧文件应该被删除 (10天前) | Old file should be deleted (10 days ago)
  OLD_DATE=$(date -d "10 days ago" -Iseconds)
  # 新文件应该保留 (1小时前) | New file should be kept (1 hour ago)
  NEW_DATE=$(date -d "1 hour ago" -Iseconds)
  
  # 创建测试文件 | Create test files
  # 1. 创建一个旧文件（应该被删除）| Create an old file (should be deleted)
  echo "This is an old file" > "$FILES_DIR/old_file.txt"
  cat > "$INFO_DIR/old_file.txt.trashinfo" <<EOF
[Trash Info]
Path=/test/old_file.txt
DeletionDate=$OLD_DATE
EOF
  
  # 2. 创建一个新文件（应该保留）| Create a new file (should be kept)
  echo "This is a new file" > "$FILES_DIR/new_file.txt"
  cat > "$INFO_DIR/new_file.txt.trashinfo" <<EOF
[Trash Info]
Path=/test/new_file.txt
DeletionDate=$NEW_DATE
EOF
  
  # 3. 创建一个没有对应文件的元数据（应该报告警告）| Create metadata without corresponding file
  cat > "$INFO_DIR/orphaned.trashinfo" <<EOF
[Trash Info]
Path=/test/orphaned.txt
DeletionDate=$OLD_DATE
EOF
  
  # 4. 创建一个没有元数据的文件（应该报告警告）| Create file without metadata
  echo "This file has no metadata" > "$FILES_DIR/no_metadata.txt"
  
  # 设置环境变量 | Set environment variables
  export TRASH_DIR FILES_DIR INFO_DIR EXPUNGED_DIR
  
  # 运行清理脚本 | Run cleanup script
  echo "运行清理脚本 (保留7天)..."
  "$REPO_DIR/clean_trash.sh" -v 7
  
  # 验证结果 | Verify results
  echo "验证结果..."
  if [ ! -f "$FILES_DIR/old_file.txt" ] && [ ! -f "$INFO_DIR/old_file.txt.trashinfo" ]; then
    echo "✓ 旧文件已正确删除"
  else
    echo "✗ 旧文件未被删除"
  fi
  
  if [ -f "$FILES_DIR/new_file.txt" ] && [ -f "$INFO_DIR/new_file.txt.trashinfo" ]; then
    echo "✓ 新文件已正确保留"
  else
    echo "✗ 新文件被错误删除"
  fi
  
  if [ -f "$INFO_DIR/orphaned.trashinfo" ]; then
    echo "✓ 孤立元数据已保留"
  else
    echo "✗ 孤立元数据被错误删除"
  fi
  
  # 清理环境变量 | Clean up environment variables
  unset TRASH_DIR FILES_DIR INFO_DIR EXPUNGED_DIR
}

test_help() {
  echo "=== 测试帮助信息 ==="
  "$REPO_DIR/clean_trash.sh" -h
  # 帮助命令应该成功执行并返回0 | Help command should execute successfully and return 0
  if [ $? -eq 0 ]; then
    echo "✓ 帮助信息显示正常"
  else
    echo "✗ 帮助信息显示异常"
  fi
}

test_invalid_args() {
  echo "=== 测试无效参数 ==="
  
  echo "测试缺少参数..."
  OUTPUT=$( "$REPO_DIR/clean_trash.sh" 2>&1 )
  EXIT_CODE=$?
  # 检查是否显示了错误信息和帮助信息 | Check if error message and help message are displayed
  if echo "$OUTPUT" | grep -q "错误：需要提供保留天数参数\|Error: Need to provide days parameter" && 
     echo "$OUTPUT" | grep -q "回收站清理工具\|Trash cleaner tool"; then
    echo "✓ 缺少参数时正确显示错误信息和帮助信息"
  else
    echo "✗ 缺少参数时未正确显示错误信息和帮助信息"
  fi
  
  echo "测试非数字参数..."
  "$REPO_DIR/clean_trash.sh" abc 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "✓ 正确拒绝非数字参数"
  else
    echo "✗ 应该失败"
  fi
  
  echo "测试负数参数..."
  "$REPO_DIR/clean_trash.sh" -1 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "✓ 正确拒绝负数参数"
  else
    echo "✗ 应该失败"
  fi
  
  echo "测试零值参数..."
  "$REPO_DIR/clean_trash.sh" 0 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "✓ 正确拒绝零值参数"
  else
    echo "✗ 应该失败"
  fi
}

test_directory_structure() {
  echo "=== 测试目录结构检查 ==="
  
  TRASH_DIR="$TEST_DIR/trash_incomplete"
  FILES_DIR="$TRASH_DIR/files"
  INFO_DIR="$TRASH_DIR/info"
  EXPUNGED_DIR="$TRASH_DIR/expunged"
  
  # 只创建部分目录 | Create only partial directories
  mkdir -p "$TRASH_DIR"
  mkdir -p "$FILES_DIR"
  # 故意不创建 info 目录 | Intentionally not creating info directory
  
  export TRASH_DIR FILES_DIR INFO_DIR EXPUNGED_DIR
  
  "$REPO_DIR/clean_trash.sh" 7 && echo "✗ 应该失败" || echo "✓ 正确拒绝不完整的目录结构"
  
  unset TRASH_DIR FILES_DIR INFO_DIR EXPUNGED_DIR
}

# 运行所有测试 | Run all tests
echo "开始测试..."
test_help
test_invalid_args
test_directory_structure
test_cleanup

# 测试详细模式
echo "=== 测试详细模式 ==="
# 使用之前的测试环境
TRASH_DIR="$TEST_DIR/trash"
FILES_DIR="$TRASH_DIR/files"
INFO_DIR="$TRASH_DIR/info"
EXPUNGED_DIR="$TRASH_DIR/expunged"

# 添加另一个旧文件用于测试
echo "This is another old file" > "$FILES_DIR/old_file2.txt"
cat > "$INFO_DIR/old_file2.txt.trashinfo" <<EOF
[Trash Info]
Path=/test/old_file2.txt
DeletionDate=$(date -d "10 days ago" -Iseconds)
EOF

export TRASH_DIR FILES_DIR INFO_DIR EXPUNGED_DIR

echo "运行详细模式清理..."
"$REPO_DIR/clean_trash.sh" -v 7

unset TRASH_DIR FILES_DIR INFO_DIR EXPUNGED_DIR

echo "测试完成。"