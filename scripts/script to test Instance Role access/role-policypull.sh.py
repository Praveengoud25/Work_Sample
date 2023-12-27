#to pull the policies and there versions to diffrent files
aws iam list-policies --profile=011821064023_mnd-l3-support-role | grep  PolicyName >>  p1
aws iam list-policies --profile=011821064023_mnd-l3-support-role | grep  DefaultVersionId >> v1

#here we remove the blank spaces, special chars and a string from the file to have corret info
awk '{gsub(/|"|,|:|PolicyName|/,"")}1' p1 > p 
awk '{ gsub(/ /,""); print }' p > policies

#here we remove the blank spaces, special chars and a string from the file to have corret info
awk '{gsub(/|"|,|:|DefaultVersionId|/,"")}1' p1 > p
awk '{ gsub(/ /,""); print }' v > versions

#using the both files we have to find the role description and save them to the respected policy named file 
#created while loop to read 2 variables 1 policies, 2 versions
while read -r policies && read -r versions <&3; do
        echo -e "policies \n$versions ";
#this cmd will
        aws iam get-policy-version --policy-arn arn:aws:iam::011821064023:policy/$policies --version-id $versions ->>  $policies-$versions
done < policies 3<versions