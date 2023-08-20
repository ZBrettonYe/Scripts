import sys
import re

input_file = sys.argv[1]
rules_file = sys.argv[2]

find_replace = {}
with open(rules_file, 'r', encoding='utf-8') as rules:
    # 使用正则提取标签中的文本
    find_pattern = re.compile(r'(?<=<find>).*?(?=<\/find>)')
    replace_pattern = re.compile(r'(?<=<replace>).*?(?=<\/replace>)')
    for line in rules:
        if line.startswith('<find>'):
            match = find_pattern.search(line)
            find = match.group(0)
        elif line.startswith('<replace>'):
            match = replace_pattern.search(line)
            find_replace[find] = match.group(0)

with open(input_file, 'r+', encoding='utf-8') as input:
    content = input.read()
    # 在内容中直接替换
    for find, replace in find_replace.items():
        content = content.replace(find, replace)
    # 操作指针到开头,清空文件,写入新内容
    input.seek(0)
    input.truncate()
    input.write(content)

print(rules_file + "替换完成!")
