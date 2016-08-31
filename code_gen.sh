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
	if [[ 
else
	echo " have no permission to write file to $2 "
	exit 1
fi
tableName=''
columns=''
dao=''
# generate dao 
doGen(){
	if [[ ! -z "$2" ]] 
	then
		columns=$( echo "$columns" | sed 's/^,\(.*\)/\1/' )
	fi
}
# read sql
while IFS='' read -r line || [[ -n "$line" ]] ; do
	content=$( echo "$line" | awk ' {print tolower($0)}' )
	if [[ "$content" =~ .*create.*table.* ]]
	then
		doGen "$tableName"  "$columns" "$dao" "$2"
		tableName=$(echo "$content" | awk '{print $(NF-1)}')
		if [[  "$tableName" =~  ^\` ]] 
		then
			tableName=$( echo "$tableName" | sed 's/^`\(.*\)`$/\1/' )
		fi
		#(^|_) at the start of the string or after an underscore - first group
		#([a-z]) single lower case letter - second group
		#\U\2 uppercasing second group
		#g globally
		dao=$( echo "$tableName" | sed -r 's/(^|_)([a-z])/\U\2/g')"DAO"
		echo "$dao"
		columns=""
	else
		if [[ $( echo "$content" | awk '{print $1}' ) =~ ^\` ]]
		then
			columns="$columns,"$( echo "$content" | awk '{print $1 }')
		fi
	fi
done < "$1"
# last 
doGen "$tableName"  "$columns" "$dao" "$2"
