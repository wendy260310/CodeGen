#!/bin/bash
# check input
if [ "$#" -ne 2 ]
then
	echo "two parameters , first is sql ,second is dao directory";
	exit 1
fi
# check input illegal
if [ -r "$1" ]
then
	echo "$1 can be read , file check success "
else
	echo "have no permission to read file $1"
	exit 1
fi
if [ -w "$2" ]
then
	echo " $2 can be access , directory check success "
else
	echo " have no permission to write file to $2 "
	exit 1
fi

table_create="create table";

# read sql

while IFS='' read -r line || [[ -n "$line" ]] ; do
	content=$( echo "$line" | awk ' {print tolower($0)}' )
	if [[ "$content" =~ .*create.*table.* ]]
	then
		tableName=$(echo "$content" | awk '{print $(NF-1)}')
	fi
done < "$1"
