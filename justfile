id := "com.forgesoftware.plugins.opendeck-vsd-n1.sdPlugin"

release next=`git cliff --bumped-version | tr -d "v"`: (bump next) package (tag next)

package: build-linux collect zip

bump next=`git cliff --bumped-version | tr -d "v"`:
    git diff --cached --exit-code

    echo "We will bump version to {{next}}, press any key"
    read ans

    sed -i 's/"Version": ".*"/"Version": "{{next}}"/g' manifest.json
    sed -i 's/^version = ".*"$/version = "{{next}}"/g' Cargo.toml

tag next=`git cliff --bumped-version | tr -d "v"`:
    echo "Generating changelog"
    git cliff -o CHANGELOG.md --tag v{{next}}

    echo "We will now commit the changes, please review before pressing any key"
    read ans

    git add .
    git commit -m "chore(release): v{{next}}"
    git tag "v{{next}}"

build-linux:
    cargo build --release --target x86_64-unknown-linux-gnu --target-dir target/plugin-linux

clean:
    sudo rm -rf target/

collect:
    rm -rf build
    mkdir -p build/{{id}}
    cp -r assets build/{{id}}
    cp manifest.json build/{{id}}
    cp LICENSE build/{{id}}
    cp target/plugin-linux/x86_64-unknown-linux-gnu/release/opendeck-vsd-n1 build/{{id}}/opendeck-vsd-n1-linux

[working-directory: "build"]
zip:
    zip -r opendeck-vsd-n1.plugin.zip {{id}}/
