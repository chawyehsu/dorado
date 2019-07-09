workflow "Excavator" {
  on = "schedule(0 * * * *)"
  resolves = ["Excavate"]
}

action "Excavate" {
  uses = "Ash258/Scoop-GithubActions@0.3.58"
  args = "Scheduled"
  env = {
      "GITH_EMAIL" = "h404bi@outlook.com"
  }
  secrets = ["GITHUB_TOKEN"]
}
