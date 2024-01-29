function har_domains
    jq -r '[ .log.entries[].request.url | capture("//(?<domain>[^/]+)") | .domain ] | unique | .[]' $argv
end
