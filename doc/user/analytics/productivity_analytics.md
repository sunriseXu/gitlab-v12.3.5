# Productivity Analytics **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/12079) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.3 (enabled by feature flags `productivity_analytics`).

Track development velocity with Productivity Analytics.

For many companies, the development cycle is a blackbox and getting an estimate of how
long, on average, it takes to deliver features is an enormous endeavor.

While [Cycle Analytics](../project/cycle_analytics.md) focuses on the entire
Software Development Life Cycle (SDLC) process, Productivity Analytics provides a way for Engineering Management to drill down in a systematic way to uncover patterns and causes for success or failure at an individual, project or group level.

Productivity can slow down for many reasons ranging from degrading code base to quickly growing teams. In order to investigate, department or team leaders can start by visualizing the time it takes for merge requests to be merged.

## Supported features

Productivity Analytics allows GitLab users to:

- Visualize typical merge request (MR) lifetime and statistics. Use a histogram that shows the distribution of the time elapsed between creating and merging merge requests.
- Drill down into the most time consuming merge requests, select a number of outliers, and filter down all subsequent charts to investigate potential causes.
- Filter by group, project, author, label, milestone, or a specific date range. Filter down, for example, to the merge requests of a specific author in a group or project during a milestone or specific date range.
- Measure velocity over time. Visualize the trends of each metric from the charts above over time in order to observe progress. Zoom in on a particular date range if you notice outliers.

## Accessing metrics and visualizations

To access the **Productivity Analytics** page:

1. Go to **Analytics** from the top navigation bar.
1. Select **Productivity Analytics** from the menu.

The following metrics and visualizations are available on a project or group level - currently only covering **merged** merge requests:

- Histogram showing the number of merge request that took a specified number of days to merge after creation. Select a specific column to filter down subsequent charts.
- Histogram showing a breakdown of the time taken (in hours) to merge a merge request. The following intervals are available:
  - Time from first commit to first comment.
  - Time from first comment until last commit.
  - Time from last commit to merge.
- Histogram showing the size or complexity of a merge request, using the following:
  - Number of commits per merge request.
  - Number of lines of code per commit.
  - Number of files touched.
- Scatterplot showing all MRs merged on a certain date, together with the days it took to complete the action and a 30 day rolling median.
  - Users can zoom in and out on specific days of interest.
- Table showing list of merge requests with their respective times and size metrics.
  - Users can sort by any of the above metrics.

## Permissions

The **Productivity Analytics** dashboard can be accessed only:

- On [Premium or Silver tier](https://about.gitlab.com/pricing/) and above.
- By users with [Reporter access](../permissions.md) and above.
