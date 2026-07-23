# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — Java Ultra Configuration                           ║
# ║  SDKMAN/jabba/mise, multiple JDKs, Maven/Gradle & full ecosystem support   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_java_loaded && exit 0
set --global _ash_java_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_java_log      "$HOME/.local/share/ash/logs/java.log"
set --global _ash_java_cache    "$HOME/.local/share/ash/cache/java"
set --global _ash_java_cache_ttl 300

mkdir -p (dirname $_ash_java_log) 2>/dev/null
mkdir -p $_ash_java_cache 2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _java_reset   (set_color normal)
set -g _java_bold    (set_color --bold)
set -g _java_orange  (set_color FF6B35)
set -g _java_cyan    (set_color cyan)
set -g _java_green   (set_color green)
set -g _java_yellow  (set_color yellow)
set -g _java_red     (set_color red)
set -g _java_blue    (set_color blue)
set -g _java_dim     (set_color brblack)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 BACKEND DETECTION: SDKMAN → mise → jabba → system                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_java_detect_backend --description "Detect best JDK version manager"
    # SDKMAN (most common for Java devs)
    if test -f "$HOME/.sdkman/bin/sdkman-init.sh"
        echo "sdkman"; return
    end

    # mise (universal version manager)
    if command -q mise && mise plugin list 2>/dev/null | grep -qE 'java|jdk'
        echo "mise"; return
    end

    # jabba (jabba version manager)
    if command -q jabba; or test -f "$HOME/.jabba/jabba.fish"
        echo "jabba"; return
    end

    # asdf
    if command -q asdf && asdf plugin list 2>/dev/null | grep -q java
        echo "asdf"; return
    end

    # jenv
    if command -q jenv
        echo "jenv"; return
    end

    # System Java
    for java_bin in \
        /usr/lib/jvm/default \
        /usr/lib/jvm/java-21-openjdk \
        /usr/lib/jvm/java-17-openjdk \
        /usr/lib/jvm/java-11-openjdk \
        /Library/Java/JavaVirtualMachines/*/Contents/Home
        if test -x "$java_bin/bin/java"
            echo "system"
            set --global _ash_java_home $java_bin
            return
        end
    end

    if command -q java
        echo "system"; return
    end

    echo "none"
end

set --global _ash_java_backend (__ash_java_detect_backend)

# Exit early if Java not found
if test "$_ash_java_backend" = none
    exit 0
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🚀 BACKEND INITIALIZERS                                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── SDKMAN ───────────────────────────────────────────────────────────────────
function __ash_java_init_sdkman --description "Initialize SDKMAN for Fish"
    set --export SDKMAN_DIR "$HOME/.sdkman"

    # Fish-compatible SDKMAN wrapper (sdkman-for-fish or manual)
    if functions -q sdk
        # Plugin already loaded (sdkman-for-fish fisher plugin)
        echo "[sdkman-fish] initialized" >> $_ash_java_log 2>/dev/null
        return
    end

    # Manual SDKMAN Fish adapter
    function sdk --description "SDKMAN wrapper for Fish shell"
        set -l cmd $argv[1]
        set -l args $argv[2..-1]

        switch $cmd
            case use
                set -l candidate $args[1]
                set -l version   $args[2]

                # Java use — update JAVA_HOME and PATH
                if test "$candidate" = java
                    set -l java_dir "$SDKMAN_DIR/candidates/java/$version"
                    if test -d $java_dir
                        set --export JAVA_HOME $java_dir
                        # Remove old java from PATH
                        set -l new_path
                        for p in $PATH
                            string match -q "$SDKMAN_DIR/candidates/java/*/bin" $p && continue
                            set --append new_path $p
                        end
                        set --export PATH $java_dir/bin $new_path
                        echo $_java_green"  ✓ Using Java $version"$_java_reset
                    else
                        echo $_java_red"  ✗ Java $version not installed. Run: sdk install java $version"$_java_reset
                    end
                else
                    # Generic candidate
                    bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && sdk use $candidate $version"
                end

            case install
                bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && sdk install $args"

            case uninstall
                bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && sdk uninstall $args"

            case list
                bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && sdk list $args"

            case current
                bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && sdk current $args"

            case upgrade
                bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && sdk upgrade $args"

            case default
                bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && sdk default $args"

            case version
                bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && sdk version"

            case selfupdate
                bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && sdk selfupdate"

            case '*'
                bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && sdk $cmd $args"
        end
    end

    # Set current Java from SDKMAN current
    set -l current_java (
        readlink -f "$SDKMAN_DIR/candidates/java/current" 2>/dev/null
    )

    if test -n "$current_java" && test -d $current_java
        set --export JAVA_HOME $current_java
        fish_add_path --prepend --global "$current_java/bin"
    end

    # Add other SDKMAN candidates to PATH
    for candidate_dir in "$SDKMAN_DIR/candidates"/*/current/bin
        test -d $candidate_dir || continue
        contains $candidate_dir $PATH || fish_add_path --append --global $candidate_dir
    end

    echo "[sdkman] initialized JAVA_HOME=$JAVA_HOME" >> $_ash_java_log 2>/dev/null
end

# ─── jabba ────────────────────────────────────────────────────────────────────
function __ash_java_init_jabba --description "Initialize jabba"
    set --export JABBA_HOME "$HOME/.jabba"

    if test -f "$JABBA_HOME/jabba.fish"
        source "$JABBA_HOME/jabba.fish"
    end

    echo "[jabba] initialized" >> $_ash_java_log 2>/dev/null
end

# ─── jenv ────────────────────────────────────────────────────────────────────
function __ash_java_init_jenv --description "Initialize jenv"
    set --export JENV_ROOT "$HOME/.jenv"
    fish_add_path --prepend --global "$JENV_ROOT/bin"
    jenv init - fish 2>/dev/null | source
    echo "[jenv] initialized" >> $_ash_java_log 2>/dev/null
end

# ─── mise ────────────────────────────────────────────────────────────────────
function __ash_java_init_mise --description "Initialize mise for Java"
    # mise activate fish handles this
    # Just ensure JAVA_HOME is set from mise
    set -l java_path (mise which java 2>/dev/null)
    if test -n "$java_path"
        set --export JAVA_HOME (dirname (dirname $java_path))
    end
    echo "[mise] java initialized" >> $_ash_java_log 2>/dev/null
end

# ─── System Java ──────────────────────────────────────────────────────────────
function __ash_java_init_system --description "Configure system Java"
    # Find best system JVM
    set -l jvm_dirs /usr/lib/jvm
    if test -d $jvm_dirs
        # Prefer newer versions
        for preferred in java-21 java-17 java-11 java-8 default java
            for jvm_dir in $jvm_dirs/$preferred*/
                if test -x "$jvm_dir/bin/java"
                    set --export JAVA_HOME (string trim -r -c '/' $jvm_dir)
                    fish_add_path --prepend --global "$JAVA_HOME/bin"
                    echo "[system] JAVA_HOME=$JAVA_HOME" >> $_ash_java_log 2>/dev/null
                    return
                end
            end
        end
    end

    # macOS
    if command -q /usr/libexec/java_home
        set --export JAVA_HOME (/usr/libexec/java_home 2>/dev/null)
        fish_add_path --prepend --global "$JAVA_HOME/bin"
    end
end

# ── Run the right initializer ─────────────────────────────────────────────────
switch $_ash_java_backend
    case sdkman
        __ash_java_init_sdkman
    case jabba
        __ash_java_init_jabba
    case jenv
        __ash_java_init_jenv
    case mise
        __ash_java_init_mise
    case system
        __ash_java_init_system
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  JAVA ENVIRONMENT                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Maven
if command -q mvn; or test -d "$HOME/.sdkman/candidates/maven/current"
    set --export MAVEN_OPTS "\
        -Xmx2g \
        -XX:+TieredCompilation \
        -XX:TieredStopAtLevel=1 \
        -Djava.awt.headless=true \
        -Dfile.encoding=UTF-8"

    set --export MAVEN_HOME (command -v mvn | xargs -r dirname | xargs -r dirname 2>/dev/null)

    # Maven local repo
    set --export MAVEN_REPO "$HOME/.m2/repository"
end

# Gradle
if command -q gradle; or test -d "$HOME/.sdkman/candidates/gradle/current"
    set --export GRADLE_USER_HOME "$HOME/.gradle"
    set --export GRADLE_OPTS "\
        -Xmx2g \
        -XX:+HeapDumpOnOutOfMemoryError \
        -Dfile.encoding=UTF-8"
end

# JVM tuning for development
set --export JVM_OPTS "\
    -Xms256m \
    -Xmx2g \
    -XX:+UseG1GC \
    -XX:+UseStringDeduplication \
    -Dfile.encoding=UTF-8 \
    -Djava.awt.headless=true"

# Spring Boot DevTools
set --export SPRING_DEVTOOLS_RESTART_ENABLED true

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔄 AUTO-SWITCHING: Detect .java-version / .sdkmanrc                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_java_resolve_version --description "Resolve required Java version from project files"
    set -l dir (pwd)

    while test "$dir" != "/"
        # .sdkmanrc (SDKMAN)
        if test -f "$dir/.sdkmanrc"
            set -l ver (grep '^java=' "$dir/.sdkmanrc" 2>/dev/null | cut -d= -f2)
            test -n "$ver" && echo $ver && return
        end

        # .java-version (jenv/jabba)
        if test -f "$dir/.java-version"
            string trim < "$dir/.java-version"
            return
        end

        # .tool-versions (asdf/mise)
        if test -f "$dir/.tool-versions"
            set -l ver (grep '^java\s' "$dir/.tool-versions" 2>/dev/null | awk '{print $2}')
            test -n "$ver" && echo $ver && return
        end

        # pom.xml java version
        if test -f "$dir/pom.xml" && command -q grep
            set -l ver (grep -oP '(?<=maven.compiler.source>)[^<]+' "$dir/pom.xml" 2>/dev/null | head -1)
            test -n "$ver" && echo $ver && return
        end

        # build.gradle java version
        if test -f "$dir/build.gradle" || test -f "$dir/build.gradle.kts"
            set -l ver (grep -oP '(?<=JavaVersion\.VERSION_)\d+' "$dir/build.gradle" "$dir/build.gradle.kts" 2>/dev/null | head -1)
            test -n "$ver" && echo $ver && return
        end

        set dir (dirname $dir)
    end
    echo ""
end

function __ash_java_auto_switch --on-variable PWD \
    --description "Auto-switch JDK on directory change"

    set -l required (__ash_java_resolve_version)
    test -z "$required" && return

    # Cache
    set -l cache_key (echo (pwd) | md5sum | awk '{print $1}')
    set -l cache_file "$_ash_java_cache/ver-$cache_key"

    if test -f $cache_file && test (cat $cache_file) = "$required"
        return
    end

    set -l current (java -version 2>&1 | head -1 | grep -oP '\d+\.\d+\.[\d_]+')
    if test "$current" = "$required"
        echo $required > $cache_file
        return
    end

    # Switch using backend
    switch $_ash_java_backend
        case sdkman
            sdk use java $required 2>/dev/null
            and echo $required > $cache_file
            and echo $_java_dim"  ☕ Java "$_java_orange$required$_java_reset" (auto)"
        case jabba
            command -q jabba && jabba use $required 2>/dev/null
            and echo $required > $cache_file
        case jenv
            jenv local $required 2>/dev/null
            and echo $required > $cache_file
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🛠️  PUBLIC FUNCTIONS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── java-info: Rich Java environment info ────────────────────────────────────
function java-info --description "Show complete Java development environment info"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l orange (set_color FF6B35)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l yellow (set_color yellow)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$orange"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$orange"  ║     ☕  Java Development Environment                 ║"$reset
    echo $bold$orange"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    echo "  "$bold"Backend:   "$reset $_ash_java_backend
    echo "  "$bold"Java:      "$reset $orange(java -version 2>&1 | head -1)$reset
    echo "  "$bold"JAVA_HOME: "$reset $dim$JAVA_HOME$reset
    echo ""

    # Build tools
    echo "  "$bold"Build Tools:"$reset
    for tool in mvn gradle ant sbt
        if command -q $tool
            set -l ver ($tool --version 2>/dev/null | head -1)
            printf "    $green%-10s$reset %s\n" $tool $dim$ver$reset
        end
    end

    # SDKMAN installed versions
    if test "$_ash_java_backend" = sdkman && test -d "$HOME/.sdkman/candidates/java"
        echo ""
        echo "  "$bold"Installed JDKs (SDKMAN):"$reset
        for jdk in "$HOME/.sdkman/candidates/java"/*/
            set -l ver (basename $jdk)
            test "$ver" = current && continue
            set -l current_marker ""
            test "$jdk" = (readlink -f "$HOME/.sdkman/candidates/java/current")/ && \
                set current_marker $green" ← current"$reset
            echo "    "$dim"• "$reset$ver$current_marker
        end
    end

    # JVM flags
    echo ""
    echo "  "$bold"Maven Opts:"$reset "  "$dim$MAVEN_OPTS$reset
    echo "  "$bold"Gradle Opts:"$reset " "$dim$GRADLE_OPTS$reset

    echo ""
end

# ─── java-jdks: List all installed JDKs ──────────────────────────────────────
function java-jdks --description "List all installed JDK versions"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l orange (set_color FF6B35)
    set -l green  (set_color green)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$orange"  ☕ Installed JDKs ($_ash_java_backend)"$reset
    echo ""

    switch $_ash_java_backend
        case sdkman
            if test -d "$HOME/.sdkman/candidates/java"
                set -l current_path (readlink -f "$HOME/.sdkman/candidates/java/current" 2>/dev/null)
                for jdk in "$HOME/.sdkman/candidates/java"/*/
                    set -l ver (basename $jdk)
                    test "$ver" = current && continue
                    set -l marker ""
                    string match -q $jdk/ $current_path/ 2>/dev/null && set marker $green" ← current"$reset
                    echo "    "$dim"•"$reset" $ver$marker"
                end
            end

        case jabba
            command -q jabba && jabba ls 2>/dev/null | while read -l line
                echo "    "$dim$line$reset
            end

        case jenv
            jenv versions 2>/dev/null | while read -l line
                echo "    "$dim$line$reset
            end

        case mise
            mise ls java 2>/dev/null | while read -l line
                echo "    "$dim$line$reset
            end

        case system
            # Find all JVMs
            for jvm_dir in /usr/lib/jvm/*/
                test -x "$jvm_dir/bin/java" || continue
                set -l ver (basename $jvm_dir)
                echo "    "$dim"•"$reset" $ver"
            end
    end
    echo ""
end

# ─── java-switch: Switch JDK version ─────────────────────────────────────────
function java-switch --description "Switch to a specific JDK version"
    set -l version $argv[1]

    if test -z "$version"
        # Interactive picker
        switch $_ash_java_backend
            case sdkman
                set version (
                    ls "$HOME/.sdkman/candidates/java" 2>/dev/null |
                    grep -v current |
                    fzf --border-label '  JDK Versions ' \
                        --border rounded \
                        --prompt '  ☕ ' \
                        --header '  Enter:switch  ' 2>/dev/null
                )
            case '*'
                echo "  Usage: java-switch <version>"
                return 1
        end
        test -z "$version" && return 0
    end

    echo $_java_orange"  ☕ Switching to JDK $version..."$_java_reset

    switch $_ash_java_backend
        case sdkman
            sdk use java $version
            set --export JAVA_HOME "$HOME/.sdkman/candidates/java/$version"
        case jabba
            jabba use $version
        case jenv
            jenv local $version
            set --export JAVA_HOME (jenv javahome 2>/dev/null)
        case mise
            mise use --global java@$version
    end

    echo ""
    echo $_java_green"  ✓ Java "(java -version 2>&1 | head -1)$_java_reset
end

# ─── java-install: Install a JDK via SDKMAN ──────────────────────────────────
function java-install --description "Install a JDK version"
    set -l version $argv[1]

    if test -z "$version"
        echo "  Common distributions:"
        echo "    21.0.2-tem    (Temurin 21 LTS)"
        echo "    17.0.9-tem    (Temurin 17 LTS)"
        echo "    11.0.21-tem   (Temurin 11 LTS)"
        echo "    21.0.2-graalce (GraalVM CE 21)"
        echo "    21.0.2-librca  (Liberica 21)"
        echo "    21-open        (OpenJDK 21)"
        echo ""
        read -P "  Version to install: " version
    end

    test -z "$version" && return 1

    switch $_ash_java_backend
        case sdkman
            sdk install java $version
        case mise
            mise install java@$version
        case jabba
            jabba install $version
        case '*'
            echo $_java_red"  ✗ Cannot auto-install with backend: $_ash_java_backend"$_java_reset
            return 1
    end
end

# ─── mvn-wrapper: Maven with sensible defaults ───────────────────────────────
function mvn-w --description "Maven with color output and timing"
    if test -f ./mvnw
        set -l ts (date +%s)
        ./mvnw --color=always $argv
        set -l elapsed (math (date +%s) - $ts)
        echo ""
        echo $_java_dim"  ⏱  Maven build: "$elapsed"s"$_java_reset
    else
        command -q mvn || begin; echo "Maven not found"; return 1; end
        set -l ts (date +%s)
        mvn $argv
        set -l elapsed (math (date +%s) - $ts)
        echo ""
        echo $_java_dim"  ⏱  Maven build: "$elapsed"s"$_java_reset
    end
end

# ─── gradle-wrapper: Gradle with sensible defaults ───────────────────────────
function gradle-w --description "Gradle wrapper with timing and color"
    set -l ts (date +%s)
    if test -f ./gradlew
        chmod +x ./gradlew 2>/dev/null
        ./gradlew --console=rich $argv
    else
        command -q gradle || begin; echo "Gradle not found"; return 1; end
        gradle --console=rich $argv
    end
    set -l elapsed (math (date +%s) - $ts)
    echo ""
    echo $_java_dim"  ⏱  Gradle build: "$elapsed"s"$_java_reset
end

# ─── java-new: Create a new Java project ──────────────────────────────────────
function java-new --description "Create a new Java project"
    set -l name    $argv[1]
    set -l type    $argv[2]   # maven | gradle | spring | quarkus | micronaut
    set -l package $argv[3]

    test -z "$name"    && read -P "  Project name: " name
    test -z "$name"    && begin; echo $_java_red"  ✗ Name required"$_java_reset; return 1; end
    test -z "$type"    && set type maven
    test -z "$package" && set package "com.$USER.$name"

    echo ""
    echo $_java_orange"  ☕ Creating Java project: $name ($type)"$_java_reset
    echo ""

    switch $type
        case maven
            if command -q mvn
                mvn archetype:generate \
                    -DgroupId=$package \
                    -DartifactId=$name \
                    -DarchetypeArtifactId=maven-archetype-quickstart \
                    -DarchetypeVersion=1.4 \
                    -DinteractiveMode=false
            else
                # Manual Maven project structure
                set -l src "$name/src/main/java/"(string replace '.' '/' $package)
                set -l test "$name/src/test/java/"(string replace '.' '/' $package)
                mkdir -p $src $test $name/src/main/resources

                # pom.xml
                printf '<?xml version="1.0" encoding="UTF-8"?>\n<project xmlns="http://maven.apache.org/POM/4.0.0">\n  <modelVersion>4.0.0</modelVersion>\n  <groupId>%s</groupId>\n  <artifactId>%s</artifactId>\n  <version>1.0-SNAPSHOT</version>\n  <properties>\n    <java.version>21</java.version>\n    <maven.compiler.source>21</maven.compiler.source>\n    <maven.compiler.target>21</maven.compiler.target>\n  </properties>\n</project>\n' \
                    $package $name > "$name/pom.xml"

                # Main class
                printf 'package %s;\n\npublic class App {\n    public static void main(String[] args) {\n        System.out.println("Hello from %s!");\n    }\n}\n' \
                    $package $name > "$src/App.java"
            end

        case gradle
            mkdir -p $name
            cd $name
            if command -q gradle
                gradle init \
                    --type java-application \
                    --dsl groovy \
                    --package $package \
                    --project-name $name \
                    --no-incubating
            else
                # Manual Gradle structure
                set -l src "src/main/java/"(string replace '.' '/' $package)
                set -l test_dir "src/test/java/"(string replace '.' '/' $package)
                mkdir -p $src $test_dir src/main/resources

                printf 'plugins {\n    id "java"\n    id "application"\n}\n\nrepositories { mavenCentral() }\n\napplication {\n    mainClass = "%s.App"\n}\n\njava {\n    sourceCompatibility = JavaVersion.VERSION_21\n    targetCompatibility = JavaVersion.VERSION_21\n}\n' \
                    $package > build.gradle

                printf 'rootProject.name = "%s"\n' $name > settings.gradle

                printf 'package %s;\n\npublic class App {\n    public static void main(String[] args) {\n        System.out.println("Hello from %s!");\n    }\n}\n' \
                    $package $name > "$src/App.java"
            end

        case spring
            echo $_java_cyan"  🌱 Creating Spring Boot project via Spring Initializr..."$_java_reset
            set -l zip_file "/tmp/spring-$name.zip"
            curl -s "https://start.spring.io/starter.zip" \
                -d "type=maven-project" \
                -d "language=java" \
                -d "bootVersion=3.2.0" \
                -d "baseDir=$name" \
                -d "groupId=$package" \
                -d "artifactId=$name" \
                -d "name=$name" \
                -d "packaging=jar" \
                -d "javaVersion=21" \
                -d "dependencies=web,actuator,devtools" \
                -o $zip_file 2>/dev/null

            if test -f $zip_file
                unzip -q $zip_file -d . 2>/dev/null
                rm -f $zip_file
                echo $_java_green"  ✓ Spring Boot project created"$_java_reset
            else
                echo $_java_red"  ✗ Failed to download from Spring Initializr"$_java_reset
                return 1
            end

        case quarkus
            echo $_java_cyan"  ⚡ Creating Quarkus project..."$_java_reset
            if command -q quarkus
                quarkus create app $package:$name:1.0-SNAPSHOT \
                    --java 21 \
                    --no-code
            else
                # Via Maven
                command -q mvn && mvn io.quarkus.platform:quarkus-maven-plugin:3.6.0:create \
                    -DprojectGroupId=$package \
                    -DprojectArtifactId=$name \
                    -Dextensions="resteasy-reactive,smallrye-health"
            end
    end

    echo ""
    echo $_java_green"  ✓ Project created: $name"$_java_reset
    echo ""
end

# ─── java-decompile: Decompile a class/jar file ───────────────────────────────
function java-decompile --description "Decompile a Java .class or .jar file"
    set -l file $argv[1]

    if test -z "$file"
        echo "  Usage: java-decompile <file.class|file.jar>"
        return 1
    end

    if command -q fernflower
        fernflower $file .
    else if test -x "$HOME/.sdkman/candidates/java/current/bin/javap"
        javap -c -p $file
    else
        javap -c -p $file 2>/dev/null
    end
end

# ─── java-heap-dump: Trigger heap dump ────────────────────────────────────────
function java-heap-dump --description "Trigger heap dump for a running JVM process"
    set -l pid $argv[1]

    if test -z "$pid"
        # Show Java processes
        set -l pid (
            jps -l 2>/dev/null |
            fzf --border-label '  Java Processes ' \
                --border rounded \
                --prompt '  ☕ ' \
                --header '  Enter:select  ' 2>/dev/null |
            awk '{print $1}'
        )
    end

    test -z "$pid" && begin; echo "  Usage: java-heap-dump <pid>"; return 1; end

    set -l dump_file "heapdump-$pid-"(date +%Y%m%d%H%M%S)".hprof"
    jmap -dump:format=b,file=$dump_file $pid 2>/dev/null
    and echo $_java_green"  ✓ Heap dump: $dump_file"$_java_reset
    or  echo $_java_red"  ✗ Failed to create heap dump"$_java_reset
end

# ─── java-processes: Show running JVM processes ───────────────────────────────
function java-processes --description "Show all running Java processes with details"
    echo ""
    echo $_java_bold$_java_orange"  ☕ Running Java Processes"$_java_reset
    echo ""
    printf "  $_java_bold%-8s  %-40s  %s$_java_reset\n" "PID" "Main Class" "Args"
    printf "  $_java_dim%s$_java_reset\n" "────────────────────────────────────────────────────────────"

    jps -lv 2>/dev/null | while read -l line
        set -l parts (string split ' ' $line)
        printf "  $_java_cyan%-8s$_java_reset  %-40s  $_java_dim%s$_java_reset\n" \
            $parts[1] $parts[2] (string join ' ' $parts[3..-1])
    end
    echo ""
end

# ─── sdkman-update: Update SDKMAN and all tools ───────────────────────────────
function sdkman-update --description "Update SDKMAN and all installed SDK candidates"
    test "$_ash_java_backend" = sdkman || begin
        echo "  SDKMAN not in use"
        return 1
    end

    echo ""
    echo $_java_cyan"  🔄 Updating SDKMAN..."$_java_reset
    sdk selfupdate 2>/dev/null
    sdk update 2>/dev/null
    sdk upgrade 2>/dev/null
    echo $_java_green"  ✓ SDKMAN updated"$_java_reset
    echo ""
end

# ─── java-clean-caches: Clean Maven/Gradle caches ────────────────────────────
function java-clean-caches --description "Clean Maven and Gradle local caches"
    echo ""
    echo $_java_yellow"  🧹 Cleaning Java build caches..."$_java_reset
    echo ""

    # Maven
    if test -d "$HOME/.m2/repository"
        set -l m2_size (du -sh "$HOME/.m2/repository" 2>/dev/null | awk '{print $1}')
        read -P "  Clean Maven .m2/repository ($m2_size)? [y/N] " clean_m2
        if string match -qi 'y*' $clean_m2
            rm -rf "$HOME/.m2/repository"
            mkdir -p "$HOME/.m2/repository"
            echo $_java_green"  ✓ Maven repository cleaned ($m2_size)"$_java_reset
        end
    end

    # Gradle
    if test -d "$HOME/.gradle/caches"
        set -l gradle_size (du -sh "$HOME/.gradle/caches" 2>/dev/null | awk '{print $1}')
        read -P "  Clean Gradle caches ($gradle_size)? [y/N] " clean_gradle
        if string match -qi 'y*' $clean_gradle
            rm -rf "$HOME/.gradle/caches"
            echo $_java_green"  ✓ Gradle caches cleaned ($gradle_size)"$_java_reset
        end
    end

    # Local build dirs
    if test -f pom.xml && command -q mvn
        mvn clean 2>/dev/null && echo $_java_green"  ✓ Maven target/ cleaned"$_java_reset
    else if test -f build.gradle; or test -f build.gradle.kts
        if test -f ./gradlew
            ./gradlew clean 2>/dev/null && echo $_java_green"  ✓ Gradle build/ cleaned"$_java_reset
        end
    end

    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ✅ COMPLETIONS                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_java_jdk_list --description "List JDK versions for completions"
    switch $_ash_java_backend
        case sdkman
            ls "$HOME/.sdkman/candidates/java" 2>/dev/null | grep -v current
        case jabba
            jabba ls 2>/dev/null | string trim
        case jenv
            jenv versions 2>/dev/null | string trim
        case mise
            mise ls java 2>/dev/null | awk '{print $2}'
    end
end

complete -c java-switch  -f -a '(__ash_java_jdk_list)' -d "JDK version"
complete -c java-install -f -d "JDK distribution version"

complete -c java-new -n 'test (count (commandline -opc)) -eq 2' \
    -f -a "maven\tMaven project" \
    -a "gradle\tGradle project" \
    -a "spring\tSpring Boot (Initializr)" \
    -a "quarkus\tQuarkus framework"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Java core
abbr --add jv     'java -version'
abbr --add jinfo  'java-info'
abbr --add jjdks  'java-jdks'
abbr --add jsw    'java-switch'
abbr --add jinst  'java-install'
abbr --add jnew   'java-new'
abbr --add jproc  'java-processes'
abbr --add jclean 'java-clean-caches'

# SDKMAN
abbr --add sk     'sdk'
abbr --add skls   'sdk list'
abbr --add sklsj  'sdk list java'
abbr --add skuse  'sdk use java'
abbr --add skcur  'sdk current'
abbr --add skupd  'sdkman-update'
abbr --add skdflt 'sdk default java'

# Maven
abbr --add mv     'mvn-w'
abbr --add mvc    'mvn-w clean'
abbr --add mvp    'mvn-w package'
abbr --add mvi    'mvn-w install'
abbr --add mvci   'mvn-w clean install'
abbr --add mvcp   'mvn-w clean package'
abbr --add mvt    'mvn-w test'
abbr --add mvst   'mvn-w test -Dtest='
abbr --add mvr    'mvn-w spring-boot:run'
abbr --add mvdep  'mvn-w dependency:tree'
abbr --add mvupd  'mvn-w versions:display-dependency-updates'
abbr --add mvskip 'mvn-w -DskipTests'
abbr --add mvq    'mvn-w -q'

# Gradle
abbr --add gw     'gradle-w'
abbr --add gwb    'gradle-w build'
abbr --add gwc    'gradle-w clean'
abbr --add gwcb   'gradle-w clean build'
abbr --add gwt    'gradle-w test'
abbr --add gwr    'gradle-w bootRun'
abbr --add gwdep  'gradle-w dependencies'
abbr --add gwproj 'gradle-w projects'
abbr --add gwtask 'gradle-w tasks'
abbr --add gwq    'gradle-w --quiet'
abbr --add gwskip 'gradle-w -x test'