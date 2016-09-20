#!/bin/bash
# dao file directory , end with /
directory=''
# database table name
tableName=''
# columns in table , split with ,
columns=''
#dao Name 
dao=''
#insert exp
insertExp=''
#update exp
updateExp=''
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
	# check if directory end with '/'
	if [[ ! "$2"  =~  /$ ]]
	then 
		directory="$2""/"
	else
		directory="$2"
	fi
else
	echo " have no permission to write file to $2 "
	exit 1
fi
# generate dao, 1-> tableName , 2-> columns,3-> dao name ,4-> dao directory , 5-> insertExp ,6 -> updateExp
doGen(){
	if [[ ! -z "$2" ]] 
	then
		# dao File full path
		local daoFile="$4""$3""DAO".java
		# remove first ,
		columns=$( echo "$2" | sed 's/^,\(.*\)/\1/' )
		insertExp=$( echo "$5" | sed 's/^,\(.*\)/\1/' )
		updateExp=$( echo "$6" | sed 's/^,\(.*\)/\1/' )
		# check dao file exist
		if [[ ! -e "$daoFile" ]] 
		then
			# touch file
			touch "$daoFile" 
		else
			rm -rf "$daoFile"
		fi
		local interfaceName="$3""DAO"
		# write to  file , EOF should not have any white space in front of the word
		cat >>"$daoFile"  <<EOF
package $( echo "$4" | sed 's/.*java\/\(.*\)/\1/' | sed 's/\(\/\)/\./g'  | sed 's/\(\.$\)//' ) ;  
import com.xiaomi.browser.thrift.model.$3; 
import net.paoding.rose.jade.annotation.DAO; 
import net.paoding.rose.jade.annotation.SQL; 
import net.paoding.rose.jade.annotation.ReturnGeneratedKeys;
import java.util.List;

@DAO(catalog="browser_local")   
public interface $interfaceName {
	String TABLE_NAME = "\`$1\`" ;
	String COLUMNS =  "$columns" ;
	
	@ReturnGeneratedKeys
	@SQL(" INSERT INTO " +TABLE_NAME +" ( " + COLUMNS + " ) VALUES ( $insertExp ) ")
	long add$3 ($3 record);

	@SQL(" DELETE FROM "+TABLE_NAME+"WHERE \`id\`=:1")
	int deleteRecordById(long id);
	

	@SQL(" SELECT \`id\`,"+COLUMNS+" FROM " +TABLE_NAME + "WHERE \`id\`=:1 ")
	List<$3> getRecordById ( long id );

	@SQL(" UPDATE "+TABLE_NAME+" SET $updateExp WHERE \`id\` =:1.id ") 
	int updateRecord( $3 record);
}
EOF
	fi
}
# read sql
while IFS='' read -r line || [[ -n "$line" ]] ; do
	content=$( echo "$line" | awk ' {print tolower($0)}' )
	if [[ "$content" =~ .*create.*table.* ]]
	then
		doGen "$tableName"  "$columns" "$dao" "$directory" "$insertExp" "$updateExp"
		#reset variables
		tableName=''
		columns=''
		dao=''
		insertExp=''
		updateExp=''
		#
		tableName=$(echo "$content" | awk '{print $(NF-1)}')
		if [[  "$tableName" =~  ^\` ]] 
		then
			tableName=$( echo "$tableName" | sed 's/^`\(.*\)`$/\1/' )
		fi
		#(^|_) at the start of the string or after an underscore - first group
		#([a-z]) single lower case letter - second group
		#\U\2 uppercasing second group
		#g globally
		dao=$( echo "$tableName" | sed -r 's/(^|_)([a-z])/\U\2/g')
		columns=""
	else
		if [[ $( echo "$content" | awk '{print $1}' ) =~ ^\` ]] && [[ ! $( echo "$content" | awk '{print $1}' ) =~  .*id.* ]]
		then
			# column value
			cl=$( echo "$content" | awk '{ print $1 }')
			# column convert to camel
			clCamel=$( echo $cl | sed 's/^`\(.*\)`$/\1/' |  sed -r 's/(_)([a-z])/\U\2/g')
			columns="$columns,$cl"
			insertExp="$insertExp,:1.$clCamel"
			updateExp="$updateExp, $cl = :1.$clCamel"
		fi
	fi
done < "$1"
# last 
doGen "$tableName"  "$columns" "$dao" "$directory" "$insertExp" "$updateExp"
