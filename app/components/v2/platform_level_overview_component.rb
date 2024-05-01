class V2::PlatformLevelOverviewComponent < V2::BaseReleaseComponent
  def initialize(release, size: :sm)
    @release = release
    @size = size
    super(@release)
  end

  attr_reader :size

  def platform_runs
    @platform_runs ||=
      @release.release_platform_runs.includes(step_runs: {deployment_runs: [:staged_rollout]})
  end

  def cross_platform?
    @release.app.cross_platform?
  end

  def grid_size
    return "grid-cols-2" if @release.release_platform_runs.size > 1
    "grid-cols-1 w-2/3"
  end

  def show_ci_info
    @size != :xs
  end
end