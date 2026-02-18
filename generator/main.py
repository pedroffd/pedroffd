import os
import requests
import json
from jinja2 import Environment, FileSystemLoader

GITHUB_TOKEN = os.getenv("GH_TOKEN")
GITHUB_USERNAME = "pedroffd"

query = """
{
  user(login: "%s") {
    repositories(first: 100, ownerAffiliations: OWNER, orderBy: {field: STARGAZERS, direction: DESC}) {
      totalCount
      nodes {
        name
        stargazerCount
        languages(first: 5, orderBy: {field: SIZE, direction: DESC}) {
          edges {
            size
            node {
              name
              color
            }
          }
        }
      }
    }
    contributionsCollection {
      totalCommitContributions
      restrictedContributionsCount
    }
    pullRequests(first: 1) {
      totalCount
    }
    issues(first: 1) {
      totalCount
    }
  }
}
""" % GITHUB_USERNAME

def fetch_stats():
    headers = {"Authorization": f"Bearer {GITHUB_TOKEN}"}
    response = requests.post("https://api.github.com/graphql", json={"query": query}, headers=headers)
    if response.status_code != 200:
        raise Exception(f"Query failed: {response.status_code}. {response.text}")
    return response.json()["data"]["user"]

def process_data(data):
    # Calculate top languages
    languages = {}
    for repo in data["repositories"]["nodes"]:
        for edge in repo["languages"]["edges"]:
            lang_name = edge["node"]["name"]
            lang_size = edge["size"]
            languages[lang_name] = languages.get(lang_name, 0) + lang_size
    
    total_size = sum(languages.values())
    top_languages = sorted(languages.items(), key=lambda x: x[1], reverse=True)[:5]
    top_languages = [{"name": n, "percent": round((s / total_size) * 100, 1)} for n, s in top_languages]

    stats = {
        "commits": data["contributionsCollection"]["totalCommitContributions"] + data["contributionsCollection"]["restrictedContributionsCount"],
        "stars": sum(repo["stargazerCount"] for repo in data["repositories"]["nodes"]),
        "prs": data["pullRequests"]["totalCount"],
        "issues": data["issues"]["totalCount"],
        "repos": data["repositories"]["totalCount"],
        "top_languages": top_languages
    }
    return stats

def render_svgs(stats):
    env = Environment(loader=FileSystemLoader("generator/templates"))
    os.makedirs("dist", exist_ok=True)
    
    templates = ["header.svg", "stats.svg", "languages.svg"]
    for template_name in templates:
        template = env.get_template(template_name)
        output = template.render(stats=stats)
        with open(f"dist/{template_name}", "w") as f:
            f.write(output)

if __name__ == "__main__":
    if not GITHUB_TOKEN:
        print("GH_TOKEN not found. Using dummy data for local test.")
        # Dummy data for testing
        stats = {
            "commits": 1243,
            "stars": 85,
            "prs": 342,
            "issues": 128,
            "repos": 45,
            "top_languages": [
                {"name": "TypeScript", "percent": 45.2},
                {"name": "Python", "percent": 30.5},
                {"name": "JavaScript", "percent": 15.3},
                {"name": "Rust", "percent": 5.0},
                {"name": "Go", "percent": 4.0}
            ]
        }
    else:
        data = fetch_stats()
        stats = process_data(data)
    
    render_svgs(stats)
    print("SVGs generated successfully in dist/")
