import os

# CONFIG — change branch if needed
GITHUB_REPO = "https://github.com/Himanshujoy/File_Transfer_App"
BRANCH = "main"
ROOT_DIR = "lib"

def generate_links():
    links = []

    for root, _, files in os.walk(ROOT_DIR):
        for file in files:
            relative_path = os.path.join(root, file).replace("\\", "/")
            link = f"{GITHUB_REPO}/blob/{BRANCH}/{relative_path}"
            links.append(link)

    return links

if __name__ == "__main__":
    print("📂 Files under lib/:\n")
    for link in generate_links():
        print(link)