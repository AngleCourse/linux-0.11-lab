#!/bin/bash
#
# calltree.sh -- Generate a calltree of a specified function in specified file/directory
#
# -- Based on cflow and tree2dotx
#

# Tree2Dot
TOP_DIR=$(dirname `readlink -f $0`)/
tree2dotx=${TOP_DIR}/tree2dotx

# Output directory
OUT_DIR=calltree
PIC_TYPE=svg
BROWSER=chromium-browser

# Input: Function Name [Directory Name]
func=$1
[ -z "$func" ] && echo "Usage: $0 func_name [dir_name], use main by default." && func=main
dir=./
[ -n "$2" ] && [ -f "$2" -o -d "$2" ] && dir=$2

# Check the function and find out its file
if [ -d "$dir" ]; then
	match=`grep " [a-zA-Z0-9_]*${func}[a-zA-Z0-9_]*(.*)" -iur $dir | grep "\.[ch]:"`
	file=`echo "$match" | cut -d ':' -f1`
else
	match="$dir"`grep " [a-zA-Z0-9_]*${func}[a-zA-Z0-9_]*(.*)" -iur $dir`
	file="$dir"
fi
[ $? -ne 0 ] && echo "Note: No such function found: $func" && exit 1
echo "Func: $func"
[ -z "$file" ] && echo "Note: No file found for $func" && exit 1

# Let users choose the target files
fileno=`echo $file | tr -c -d ' ' | wc -c`
((fileno+=1))
if [ $fileno -ne 1 ]; then
	echo "Match: $fileno"
	echo "File:"
	echo "$match" | cat -n
	files=($file)
	read -p "Select: 1 ~ $fileno ? " file_in
	while [ $file_in -lt 1 -o $file_in -gt $fileno ]; do
		read -p "Select: 1 ~ $fileno ? " file_in
	done
	((file_in-=1))
	file=${files[$file_in]}
	((file_in+=1))
else
	file_in=1
fi
[ -z "$file" ] && echo "Note: No file found for $func" && exit 1
echo "File: $file"
func=`echo "$match" | sed -n -e "${file_in},${file_in}p" | sed -n -e "s/.* \([a-zA-Z0-9_]*${func}[a-zA-Z0-9_]*\)(.*).*/\1/p"`
[ -z "$func" ] && echo "Note: No such function found: $func" && exit 1

# Genrate the calling tree of this function
# Convert it to .dot format with tree2dotx
# Convert it to jpg format with dot of Graphviz
tmp=`echo $file | tr '/' '_' | tr '.' '_'`
pic=${OUT_DIR}/${func}.${tmp}.${PIC_TYPE}
which cflow 2>&1 > /dev/null
if [ $? -ne 0 ]; then
        echo "Note: cflow doesn't exist, please install it..."
        sleep 2
        echo "Note: Use calltree instead for this test."
        sleep 2
        calltree="${TOP_DIR}/calltree -b -np list="
else
        calltree="cflow -b -m "
fi
${calltree}${func} ${file} | ${tree2dotx} 2>/dev/null | dot -T${PIC_TYPE} -o ${TOP_DIR}/../$pic

# Tell users
echo "Target: ${file}: ${func} -> ${pic}"

# Display it
$BROWSER ${pic} &
