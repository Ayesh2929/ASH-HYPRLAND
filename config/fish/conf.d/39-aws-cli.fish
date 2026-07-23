# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — AWS CLI Ultra Configuration                        ║
# ║  AWS CLI v2 with profile mgmt, SSO, MFA, resource browser & full ecosystem ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_aws_loaded && exit 0
set --global _ash_aws_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 DETECTION                                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

command -q aws || exit 0

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_aws_log    "$HOME/.local/share/ash/logs/aws.log"
set --global _ash_aws_cache  "$HOME/.local/share/ash/cache/aws"

mkdir -p (dirname $_ash_aws_log) 2>/dev/null
mkdir -p $_ash_aws_cache         2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _aws_reset   (set_color normal)
set -g _aws_bold    (set_color --bold)
set -g _aws_cyan    (set_color cyan)
set -g _aws_green   (set_color green)
set -g _aws_yellow  (set_color yellow)
set -g _aws_red     (set_color red)
set -g _aws_blue    (set_color blue)
set -g _aws_dim     (set_color brblack)
set -g _aws_orange  (set_color FF9900)   # AWS orange

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  ENVIRONMENT SETUP                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Core config ────────────────────────────────────────────────────────────────
set --export AWS_CONFIG_FILE          "$HOME/.aws/config"
set --export AWS_SHARED_CREDENTIALS_FILE "$HOME/.aws/credentials"

# CLI v2 pager (use bat if available)
if command -q bat
    set --export AWS_PAGER "bat --language=json --style=plain --color=always"
else
    set --export AWS_PAGER "less -R"
end

# Retry configuration
set --export AWS_MAX_ATTEMPTS    5
set --export AWS_RETRY_MODE      standard

# Default output format (override per-command)
set --export AWS_DEFAULT_OUTPUT  json

# SDK tracing (off by default)
set --export AWS_SDK_LOAD_CONFIG 1

# Completion
aws --cli-auto-prompt off 2>/dev/null

# ── Shell completions ──────────────────────────────────────────────────────────
complete -c aws -f -a '(begin; set -l COMP_SHELL fish; set -l COMP_LINE (commandline); aws_completer; end 2>/dev/null)'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 DYNAMIC COMPLETION SOURCES                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __aws_profiles --description "List AWS profiles"
    aws configure list-profiles 2>/dev/null
end

function __aws_regions --description "List AWS regions"
    set -l cache "$_ash_aws_cache/regions"
    if test -f $cache
        set -l age (math (date +%s) - (stat -c %Y $cache 2>/dev/null; or echo 0))
        test $age -lt 86400 && cat $cache && return
    end
    aws ec2 describe-regions \
        --query 'Regions[].RegionName' \
        --output text 2>/dev/null | tr '\t' '\n' | sort | tee $cache
end

function __aws_ec2_instances --description "List EC2 instance IDs and names"
    aws ec2 describe-instances \
        --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name]' \
        --output text 2>/dev/null | \
        awk '{printf "%s\t%s (%s)\n", $1, ($2=="None"?"":$2), $3}'
end

function __aws_s3_buckets --description "List S3 buckets"
    set -l cache "$_ash_aws_cache/s3-buckets-(aws configure get profile 2>/dev/null)"
    if test -f $cache
        set -l age (math (date +%s) - (stat -c %Y $cache 2>/dev/null; or echo 0))
        test $age -lt 300 && cat $cache && return
    end
    aws s3 ls 2>/dev/null | awk '{print $3}' | tee $cache
end

function __aws_ecr_repos --description "List ECR repositories"
    aws ecr describe-repositories \
        --query 'repositories[].repositoryName' \
        --output text 2>/dev/null | tr '\t' '\n'
end

function __aws_lambda_functions --description "List Lambda functions"
    aws lambda list-functions \
        --query 'Functions[].FunctionName' \
        --output text 2>/dev/null | tr '\t' '\n'
end

function __aws_ecs_clusters --description "List ECS clusters"
    aws ecs list-clusters \
        --query 'clusterArns[]' \
        --output text 2>/dev/null | \
        tr '\t' '\n' | \
        xargs -I{} basename {}
end

function __aws_rds_instances --description "List RDS instances"
    aws rds describe-db-instances \
        --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceClass,DBInstanceStatus]' \
        --output text 2>/dev/null | \
        awk '{printf "%s\t%s (%s)\n", $1, $2, $3}'
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔐 PROFILE & AUTH MANAGEMENT                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── aws-profile: Switch AWS profile ──────────────────────────────────────────
function aws-profile --description "Switch AWS profile with fuzzy picker"
    set -l profile $argv[1]

    if test -z "$profile"
        if command -q fzf
            set profile (
                aws configure list-profiles 2>/dev/null |
                fzf --ansi \
                    --border-label "  ☁️  Select AWS Profile " \
                    --border rounded \
                    --prompt "  ☁  " \
                    --pointer "▶" \
                    --preview 'aws configure list --profile {} 2>/dev/null' \
                    --preview-window 'right:45%:border-rounded' \
                    --header "  Current: $AWS_PROFILE  "
            )
            test -z "$profile" && return 0
        else
            echo ""
            echo $_aws_bold$_aws_orange"  ☁️  AWS Profiles"$_aws_reset
            echo ""
            aws configure list-profiles 2>/dev/null | while read -l p
                set -l marker ""
                test "$p" = "$AWS_PROFILE" && set marker $_aws_green" ← active"$_aws_reset
                echo "    "$_aws_dim"• "$_aws_reset$p$marker
            end
            echo ""
            echo "  Usage: aws-profile <name>"
            return
        end
    end

    set --export AWS_PROFILE $profile

    # Detect region for this profile
    set -l region (aws configure get region --profile $profile 2>/dev/null)
    test -n "$region" && set --export AWS_DEFAULT_REGION $region

    # Invalidate cache
    rm -f "$_ash_aws_cache/s3-buckets-$profile" 2>/dev/null

    echo ""
    echo $_aws_green"  ✓ AWS Profile: $profile"$_aws_reset
    test -n "$region" && echo "  Region: "$_aws_cyan$region$_aws_reset
    echo ""

    # Verify credentials
    set -l identity (aws sts get-caller-identity --profile $profile 2>/dev/null)
    if test $status -eq 0
        set -l acct (echo $identity | command -q jq && jq -r '.Account' || echo "")
        set -l arn  (echo $identity | command -q jq && jq -r '.Arn'     || echo "")
        echo "  Account: "$_aws_dim$acct$_aws_reset
        echo "  ARN:     "$_aws_dim$arn$_aws_reset
    else
        echo $_aws_yellow"  ⚠  Could not verify credentials (SSO login may be needed)"$_aws_reset
    end
    echo ""
end

# ─── aws-sso-login: SSO login flow ────────────────────────────────────────────
function aws-sso-login --description "Login to AWS SSO for current or specified profile"
    set -l profile $argv[1]
    test -z "$profile" && set profile $AWS_PROFILE
    test -z "$profile" && set profile default

    echo ""
    echo $_aws_orange"  ☁️  AWS SSO Login: $profile"$_aws_reset
    echo ""

    aws sso login --profile $profile
    set -l rc $status

    if test $rc -eq 0
        echo ""
        echo $_aws_green"  ✓ SSO login successful"$_aws_reset
        # Update profile env
        aws-profile $profile
    else
        echo $_aws_red"  ✗ SSO login failed"$_aws_reset
    end
    return $rc
end

# ─── aws-mfa: Assume role with MFA ────────────────────────────────────────────
function aws-mfa --description "Get temporary credentials with MFA"
    set -l profile $argv[1]
    set -l mfa_serial $argv[2]
    test -z "$profile" && set profile $AWS_PROFILE

    # Get MFA serial if not provided
    if test -z "$mfa_serial"
        set mfa_serial (aws iam list-mfa-devices \
            --profile $profile \
            --query 'MFADevices[0].SerialNumber' \
            --output text 2>/dev/null)
    end

    if test -z "$mfa_serial" || test "$mfa_serial" = None
        echo $_aws_red"  ✗ No MFA device found for profile: $profile"$_aws_reset
        return 1
    end

    read -P "  MFA token code: " token

    set -l creds (aws sts get-session-token \
        --profile $profile \
        --serial-number $mfa_serial \
        --token-code $token \
        --output json 2>/dev/null)

    if test $status -eq 0 && command -q jq
        set --export AWS_ACCESS_KEY_ID     (echo $creds | jq -r '.Credentials.AccessKeyId')
        set --export AWS_SECRET_ACCESS_KEY (echo $creds | jq -r '.Credentials.SecretAccessKey')
        set --export AWS_SESSION_TOKEN     (echo $creds | jq -r '.Credentials.SessionToken')
        set --export AWS_CREDENTIAL_EXPIRATION (echo $creds | jq -r '.Credentials.Expiration')

        echo ""
        echo $_aws_green"  ✓ MFA credentials set"$_aws_reset
        echo "  Expires: "$_aws_dim$AWS_CREDENTIAL_EXPIRATION$_aws_reset
        echo ""
    else
        echo $_aws_red"  ✗ MFA authentication failed"$_aws_reset
        return 1
    end
end

# ─── aws-region: Switch AWS region ────────────────────────────────────────────
function aws-region --description "Switch AWS region with fuzzy picker"
    set -l region $argv[1]

    if test -z "$region" && command -q fzf
        set region (
            __aws_regions |
            fzf --ansi \
                --border-label "  🌍 Select AWS Region " \
                --border rounded \
                --prompt "  🌍 " \
                --pointer "▶" \
                --header "  Current: $AWS_DEFAULT_REGION  "
        )
        test -z "$region" && return 0
    end

    test -z "$region" && begin; echo "  Usage: aws-region <region>"; return 1; end

    set --export AWS_DEFAULT_REGION $region
    aws configure set region $region 2>/dev/null

    echo $_aws_green"  ✓ Region: $region"$_aws_reset
end

# ─── aws-whoami: Show current identity ────────────────────────────────────────
function aws-whoami --description "Show current AWS identity"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l orange (set_color FF9900)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$orange"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$orange"  ║     ☁️   AWS Identity                                 ║"$reset
    echo $bold$orange"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    echo "  "$bold"Profile: "$reset $cyan(test -n "$AWS_PROFILE" && echo $AWS_PROFILE || echo "default")$reset
    echo "  "$bold"Region:  "$reset $cyan(test -n "$AWS_DEFAULT_REGION" && echo $AWS_DEFAULT_REGION || aws configure get region 2>/dev/null)$reset
    echo ""

    set -l identity (aws sts get-caller-identity --output json 2>/dev/null)
    if test $status -eq 0 && command -q jq
        echo "  "$bold"Account: "$reset $cyan(echo $identity | jq -r '.Account')$reset
        echo "  "$bold"ARN:     "$reset $dim(echo $identity | jq -r '.Arn')$reset
        echo "  "$bold"User ID: "$reset $dim(echo $identity | jq -r '.UserId')$reset

        if test -n "$AWS_SESSION_TOKEN"
            echo ""
            echo "  "$green"MFA session active"$reset
            test -n "$AWS_CREDENTIAL_EXPIRATION" && \
                echo "  "$bold"Expires: "$reset $dim$AWS_CREDENTIAL_EXPIRATION$reset
        end
    else
        echo "  "$yellow"⚠  Could not get identity (check credentials)"$reset
    end
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🖥️  EC2 MANAGEMENT                                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── aws-ec2-ls: Rich EC2 instance listing ────────────────────────────────────
function aws-ec2-ls --description "List EC2 instances in rich format"
    set -l state $argv[1]
    test -z "$state" && set state "running"

    set -l reset (set_color normal)
    set -l bold  (set_color --bold)
    set -l cyan  (set_color cyan)
    set -l green (set_color green)
    set -l red   (set_color red)
    set -l dim   (set_color brblack)

    echo ""
    echo $bold"  ☁️  EC2 Instances ($state)"$reset
    echo ""
    printf "  $bold%-22s  %-20s  %-15s  %-12s  %s$reset\n" \
        "ID" "Name" "Type" "State" "IP"
    printf "  $dim%s$reset\n" "──────────────────────────────────────────────────────────────────"

    aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=$state" \
        --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],InstanceType,State.Name,PublicIpAddress,PrivateIpAddress]' \
        --output json 2>/dev/null | \
        command -q python3 && python3 -c "
import json, sys
instances = json.load(sys.stdin)
for i in instances:
    iid   = i[0] or ''
    name  = i[1] or '(no name)'
    itype = i[2] or ''
    state = i[3] or ''
    pub   = i[4] or ''
    priv  = i[5] or ''
    ip    = pub if pub else priv
    state_sym = '●' if state=='running' else '○'
    print(f'  {state_sym} {iid:<22}  {name:<20}  {itype:<15}  {state:<12}  {ip}')
" 2>/dev/null
    echo ""
end

# ─── aws-ec2-ssh: SSH into EC2 instance ──────────────────────────────────────
function aws-ec2-ssh --description "SSH into an EC2 instance via SSM or direct"
    set -l instance $argv[1]
    set -l method   $argv[2]
    test -z "$method" && set method ssm

    if test -z "$instance" && command -q fzf
        set instance (
            __aws_ec2_instances |
            fzf --ansi \
                --border-label "  🖥️  Select Instance " \
                --border rounded \
                --prompt "  🔌 " \
                --pointer "▶" \
                --header "  Enter:connect  " \
            | awk '{print $1}'
        )
        test -z "$instance" && return 0
    end

    switch $method
        case ssm
            echo $_aws_cyan"  🔌 SSM session: $instance"$_aws_reset
            aws ssm start-session --target $instance $argv[3..-1]

        case direct ssh
            set -l ip (aws ec2 describe-instances \
                --instance-ids $instance \
                --query 'Reservations[0].Instances[0].PublicIpAddress' \
                --output text 2>/dev/null)
            test -z "$ip" || test "$ip" = None && begin
                echo $_aws_red"  ✗ No public IP found"$_aws_reset; return 1
            end
            set -l key_file $argv[3]
            test -z "$key_file" && set key_file "$HOME/.ssh/id_ed25519"
            echo $_aws_cyan"  🔌 SSH: $ip"$_aws_reset
            ssh -i $key_file ec2-user@$ip
    end
end

# ─── aws-ec2-start/stop: Control instances ────────────────────────────────────
function aws-ec2-start --description "Start EC2 instances"
    set -l instance $argv[1]
    test -z "$instance" && begin; echo "  Usage: aws-ec2-start <instance-id>"; return 1; end

    aws ec2 start-instances --instance-ids $instance 2>/dev/null
    and echo $_aws_green"  ✓ Starting: $instance"$_aws_reset
end

function aws-ec2-stop --description "Stop EC2 instances"
    set -l instance $argv[1]
    test -z "$instance" && begin; echo "  Usage: aws-ec2-stop <instance-id>"; return 1; end

    echo $_aws_yellow"  ⏹  Stopping: $instance"$_aws_reset
    read -P "  Confirm? [y/N] " confirm
    string match -qi 'y*' $confirm || return 0

    aws ec2 stop-instances --instance-ids $instance 2>/dev/null
    and echo $_aws_green"  ✓ Stopping"$_aws_reset
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🪣 S3 MANAGEMENT                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── aws-s3-ls: Rich S3 listing ───────────────────────────────────────────────
function aws-s3-ls --description "List S3 buckets or bucket contents"
    set -l target $argv[1]

    if test -z "$target"
        echo ""
        echo $_aws_bold$_aws_orange"  🪣 S3 Buckets"$_aws_reset
        echo ""
        aws s3 ls 2>/dev/null | while read -l date time bucket
            printf "  $_aws_cyan%-40s$_aws_reset  $_aws_dim%s %s$_aws_reset\n" $bucket $date $time
        end
        echo ""
    else
        aws s3 ls s3://$target $argv[2..-1]
    end
end

# ─── aws-s3-browse: Interactive S3 browser ────────────────────────────────────
function aws-s3-browse --description "Browse S3 buckets and objects interactively"
    command -q fzf || begin; aws-s3-ls; return; end

    set -l bucket $argv[1]

    if test -z "$bucket"
        set bucket (
            __aws_s3_buckets |
            fzf --ansi \
                --border-label "  🪣 S3 Buckets " \
                --border rounded \
                --prompt "  🪣 " \
                --pointer "▶" \
                --preview 'aws s3 ls s3://{} --recursive --human-readable 2>/dev/null | head -20' \
                --preview-window 'right:50%:border-rounded:wrap'
        )
        test -z "$bucket" && return 0
    end

    # Browse bucket
    set -l prefix $argv[2]
    aws s3 ls "s3://$bucket/$prefix" --recursive --human-readable 2>/dev/null | \
        fzf --ansi \
            --border-label "  📄 s3://$bucket/$prefix " \
            --border rounded \
            --prompt "  📄 " \
            --pointer "▶" \
            --multi \
            --header '  Enter:download  Ctrl-U:upload  Ctrl-D:delete  ' \
            --bind "ctrl-u:execute(aws s3 cp {} s3://$bucket/{})" \
        | awk '{print $NF}' | while read -l key
            echo "s3://$bucket/$key"
        end
end

# ─── aws-s3-sync-smart: Smart sync with progress ──────────────────────────────
function aws-s3-sync-smart --description "Sync with S3 showing progress"
    set -l src  $argv[1]
    set -l dest $argv[2]

    if test -z "$src" || test -z "$dest"
        echo "  Usage: aws-s3-sync-smart <src> <dest>"
        echo "  Example: aws-s3-sync-smart ./dist s3://my-bucket/app"
        return 1
    end

    echo ""
    echo $_aws_cyan"  📤 Syncing: $src → $dest"$_aws_reset
    echo ""

    aws s3 sync $src $dest \
        --progress \
        --human-readable \
        $argv[3..-1]

    and echo $_aws_green"  ✓ Sync complete"$_aws_reset
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔧 SERVICE-SPECIFIC FUNCTIONS                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── aws-lambda-invoke: Invoke Lambda function ────────────────────────────────
function aws-lambda-invoke --description "Invoke a Lambda function"
    set -l func    $argv[1]
    set -l payload $argv[2]

    if test -z "$func" && command -q fzf
        set func (
            __aws_lambda_functions |
            fzf --border-label "  λ Select Lambda " \
                --border rounded \
                --prompt "  λ " \
                --pointer "▶" \
                --preview 'aws lambda get-function-configuration --function-name {} 2>/dev/null | python3 -m json.tool | head -30' \
                --preview-window 'right:50%:border-rounded:wrap'
        )
        test -z "$func" && return 0
    end

    test -z "$payload" && set payload '"{}"'

    set -l output_file "/tmp/lambda-response-"(date +%s)".json"

    echo ""
    echo $_aws_cyan"  λ Invoking: $func"$_aws_reset
    echo ""

    aws lambda invoke \
        --function-name $func \
        --payload "$payload" \
        --log-type Tail \
        --cli-binary-format raw-in-base64-out \
        $output_file 2>/dev/null

    if test $status -eq 0 && test -f $output_file
        echo ""
        echo $_aws_bold"  Response:"$_aws_reset
        command -q bat && bat --language=json --style=plain --color=always $output_file \
            || cat $output_file
        rm -f $output_file
    end
    echo ""
end

# ─── aws-logs: CloudWatch log streaming ───────────────────────────────────────
function aws-logs --description "Stream CloudWatch logs"
    set -l log_group $argv[1]
    set -l filter    $argv[2]

    if test -z "$log_group" && command -q fzf
        set log_group (
            aws logs describe-log-groups \
                --query 'logGroups[].logGroupName' \
                --output text 2>/dev/null | tr '\t' '\n' |
            fzf --ansi \
                --border-label "  📜 CloudWatch Log Groups " \
                --border rounded \
                --prompt "  📋 " \
                --pointer "▶" \
                --preview 'aws logs describe-log-streams --log-group-name {} --query "logStreams[0].logStreamName" --output text 2>/dev/null' \
                --preview-window 'down:3:border-rounded'
        )
        test -z "$log_group" && return 0
    end

    echo ""
    echo $_aws_cyan"  📜 Streaming: $log_group"$_aws_reset
    echo ""

    set -l tail_cmd aws logs tail $log_group --follow

    test -n "$filter" && set tail_cmd $tail_cmd --filter-pattern "$filter"

    eval $tail_cmd $argv[3..-1]
end

# ─── aws-ecr-login: Login to ECR ──────────────────────────────────────────────
function aws-ecr-login --description "Login Docker to ECR registry"
    set -l region (aws configure get region 2>/dev/null)
    test -z "$region" && set region $AWS_DEFAULT_REGION
    test -z "$region" && set region "us-east-1"

    set -l account (aws sts get-caller-identity \
        --query Account --output text 2>/dev/null)

    if test -z "$account"
        echo $_aws_red"  ✗ Could not get AWS account ID"$_aws_reset
        return 1
    end

    set -l registry "$account.dkr.ecr.$region.amazonaws.com"

    echo ""
    echo $_aws_cyan"  🔐 Logging into ECR: $registry"$_aws_reset

    aws ecr get-login-password --region $region 2>/dev/null | \
        docker login --username AWS --password-stdin $registry

    and echo $_aws_green"  ✓ ECR login successful"$_aws_reset
    echo ""
end

# ─── aws-costs: Show estimated costs ──────────────────────────────────────────
function aws-costs --description "Show AWS cost and usage"
    set -l days $argv[1]
    test -z "$days" && set days 30

    set -l end_date   (date +%Y-%m-%d)
    set -l start_date (date -d "$days days ago" +%Y-%m-%d 2>/dev/null; \
        or date -v "-$days"d +%Y-%m-%d 2>/dev/null)

    echo ""
    echo $_aws_bold$_aws_orange"  💰 AWS Costs (last $days days)"$_aws_reset
    echo ""

    aws ce get-cost-and-usage \
        --time-period Start=$start_date,End=$end_date \
        --granularity MONTHLY \
        --metrics BlendedCost \
        --group-by Type=DIMENSION,Key=SERVICE \
        --query 'ResultsByTime[].Groups[?Metrics.BlendedCost.Amount>`0.01`].[Keys[0],Metrics.BlendedCost.Amount,Metrics.BlendedCost.Unit]' \
        --output text 2>/dev/null | \
        sort -k2 -rn | \
        while read -l service amount unit
            printf "  $_aws_cyan%-50s$_aws_reset  $_aws_yellow%8.2f$_aws_reset %s\n" \
                $service $amount $unit
        end

    echo ""
    # Total
    aws ce get-cost-and-usage \
        --time-period Start=$start_date,End=$end_date \
        --granularity MONTHLY \
        --metrics BlendedCost \
        --query 'ResultsByTime[].Total.BlendedCost.Amount' \
        --output text 2>/dev/null | \
        awk '{sum+=$1} END {printf "  Total: $%.2f\n", sum}'
    echo ""
end

# ─── aws-info: Full AWS environment dashboard ─────────────────────────────────
function aws-info --description "Show complete AWS environment information"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l orange (set_color FF9900)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$orange"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$orange"  ║     ☁️   AWS CLI Dashboard                            ║"$reset
    echo $bold$orange"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    echo "  "$bold"CLI Version: "$reset $dim(aws --version 2>/dev/null)$reset
    echo "  "$bold"Profile:     "$reset $cyan(test -n "$AWS_PROFILE" && echo $AWS_PROFILE || echo "default")$reset
    echo "  "$bold"Region:      "$reset $cyan(test -n "$AWS_DEFAULT_REGION" && echo $AWS_DEFAULT_REGION || aws configure get region 2>/dev/null || echo "not set")$reset
    echo "  "$bold"Config:      "$reset $dim$AWS_CONFIG_FILE$reset
    echo ""

    # Identity
    set -l id (aws sts get-caller-identity --output json 2>/dev/null)
    if test $status -eq 0 && command -q jq
        echo "  "$bold"Account: "$reset $cyan(echo $id | jq -r '.Account')$reset
        echo "  "$bold"ARN:     "$reset $dim(echo $id | jq -r '.Arn')$reset
    else
        echo "  "$yellow"⚠  Credentials not configured or expired"$reset
    end

    echo ""
    echo "  "$bold"Profiles:"$reset
    aws configure list-profiles 2>/dev/null | while read -l p
        set -l active ""
        test "$p" = "$AWS_PROFILE" && set active $green" ← active"$reset
        echo "    "$dim"• "$reset$p$active
    end

    echo ""
    echo "  "$bold"Tools:"$reset
    for tool in aws-vault saml2aws assume granted chamber sops
        command -q $tool && echo "    "$green"✓ "$reset$tool
    end
    echo ""
end

# ─── aws-nuke-confirm: List resources before any destructive operation ─────────
function aws-resource-summary --description "Show count of key AWS resources"
    echo ""
    echo $_aws_bold$_aws_orange"  ☁️  AWS Resource Summary"$_aws_reset
    echo ""

    for svc_query in \
        "EC2 Instances:ec2 describe-instances --query 'length(Reservations[].Instances[])'" \
        "S3 Buckets:s3api list-buckets --query 'length(Buckets)'" \
        "Lambda Functions:lambda list-functions --query 'length(Functions)'" \
        "RDS Instances:rds describe-db-instances --query 'length(DBInstances)'" \
        "ECS Clusters:ecs list-clusters --query 'length(clusterArns)'"

        set -l label (string split ':' $svc_query)[1]
        set -l query (string split ':' $svc_query | tail -1)

        set -l count (eval aws $query --output text 2>/dev/null)
        test -z "$count" && set count "0"

        printf "  $_aws_cyan%-25s$_aws_reset  %s\n" "$label:" $count
    end
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Profile & Auth
abbr --add awsp    'aws-profile'
abbr --add awsw    'aws-whoami'
abbr --add awssso  'aws-sso-login'
abbr --add awsmfa  'aws-mfa'
abbr --add awsreg  'aws-region'
abbr --add awsinfo 'aws-info'

# EC2
abbr --add ec2ls   'aws-ec2-ls'
abbr --add ec2ssh  'aws-ec2-ssh'
abbr --add ec2st   'aws-ec2-start'
abbr --add ec2sp   'aws-ec2-stop'

# S3
abbr --add s3ls    'aws-s3-ls'
abbr --add s3b     'aws-s3-browse'
abbr --add s3sync  'aws-s3-sync-smart'
abbr --add s3cp    'aws s3 cp'
abbr --add s3mv    'aws s3 mv'
abbr --add s3rm    'aws s3 rm'

# Lambda
abbr --add lsinv   'aws-lambda-invoke'
abbr --add lsls    "aws lambda list-functions --query 'Functions[].FunctionName' --output table"

# Logs
abbr --add cwlogs  'aws-logs'
abbr --add cwls    "aws logs describe-log-groups --query 'logGroups[].logGroupName' --output table"

# ECR
abbr --add ecrl    'aws-ecr-login'
abbr --add ecrls   "aws ecr describe-repositories --query 'repositories[].repositoryName' --output table"

# ECS
abbr --add ecsls   "aws ecs list-clusters --output table"

# Cost
abbr --add awscost 'aws-costs'
abbr --add awsres  'aws-resource-summary'

# General
abbr --add awsver  'aws --version'
abbr --add awscfg  'aws configure'
abbr --add awscfgl 'aws configure list'
abbr --add awscfgp 'aws configure list-profiles'