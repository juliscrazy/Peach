build () {
    if [[ $args == *"r"* ]]
    then
        sudo systemctl stop peach
    fi
    printf "Building project\n"
    mkdir -p build || fail

    printf "Copying files..."
    cp launchcfg.json build/launchcfg.json
    printf "done\n"

    printf "Collecting dependencies..."
    if [[ $args == *"d"* ]]
    then
    go mod download
    fi
    printf "done\n"

    builddiscordclient
    buildcoordinator
    buildlauncher
    printf "Build complete\n"
    if [[ $args == *"i"* ]]
    then
        waittillstopped
        cp build/. /home/peach -r || fail
        cp peach.service /etc/systemd/system/peach.service
        sudo systemctl daemon-reload
    fi
    if [[ $args == *"r"* ]]
    then
        sudo systemctl start peach
    fi
}

hash () {
    mkdir -p scripts/hash || fail
    newhash=$(find ./src/$1 -type f -print0  | xargs -0 sha1sum)
    echo $newhash > scripts/hash/$1_new.hash
    newhash=$(<scripts/hash/$1_new.hash)
    rm scripts/hash/$1_new.hash
    if [[ -f "scripts/hash/$1.hash" ]];
    then
        oldhash=$(<scripts/hash/$1.hash)
    else
        oldhash=""
    fi
    if [[ "$oldhash" == "$newhash" ]];
    then
        retval=1
    else
        retval=0
    fi
    return "$retval"
}

storehash () {
    newhash=$(find ./src/$1 -type f -print0  | xargs -0 sha1sum)
    echo $newhash > scripts/hash/$1.hash
}

waittillstopped() {
    retries=20
    stopped=false
    while [ retries > 0 ] && [ stopped == false ]
    do
        systemctl is-active --quiet service && stopped=true
        sleep 1
    done
    if [ stopped == false ]
    then
        echo "Service still running after waiting for 20 seconds!"
        fail
    fi
}

buildcoordinator() {
    printf "Building client coordinator"

    #check hash
    hash "peach_client_coordinator"
    h=$?
    if [[ "$h" == "1" ]]; then 
        printf "\nSkipping. No changes were made.\n"
        return
    fi

    printf "\nCompiling..."
    go build -o build/coordinator.exe ./src/peach_client_coordinator || fail
    printf "\nDone building client coordinator\n"
    storehash "peach_client_coordinator"
}

builddiscordclient() {
    printf "Building discord client"

    #check hash
    hash "peach_discord_client"
    h=$?
    if [[ "$h" == "1" ]]; then 
        printf "\nSkipping. No changes were made.\n"
        return
    fi

    printf "\nCompiling..."
    version=$(git describe --tags)
    branch=$(git branch --show-current)
    if [[ "$branch" == "master" ]]; then
        branch=""
    else
        branch="-$branch"
    fi
    version=${version%-?-*}
    version="$version$branch"
    printf "package main\n\nconst VERSION = \"$version\"" > src/peach_discord_client/version.go
    go build -o build/discordclient.exe ./src/peach_discord_client || fail
    printf "\nDone building discord client\n"
    storehash "peach_discord_client"
}

buildlauncher() {
    printf "Building launcher"

    #check hash
    hash "peach_launcher"
    h=$?
    if [[ "$h" == "1" ]]; then 
        printf "\nSkipping. No changes were made.\n"
        return
    fi

    printf "\nCompiling..."
    go build -o build/launcher.exe ./src/peach_launcher || fail
    printf "\nDone building launcher\n"
    storehash "peach_launcher"
}

fail() {
    printf "Build failed\n"
    exit
}

args=$1
if [[ $args == "-"* ]]
then
    if [[ $args == *"h"* ]]
    then
        printf "Builds the project\nUsage: ./build.sh [OPTIONS]\n\nOptions:\n    -h  prints this page\n    -i  installs built project\n    -d  installs dependencies\n    -r  restarts the system service\n"
        exit
    fi
fi
build