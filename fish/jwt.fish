function jwt
    jq -R 'split(".",.)[] | try @base64d | try fromjson'
end

