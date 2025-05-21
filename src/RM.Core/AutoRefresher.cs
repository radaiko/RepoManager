using RM.Base;

namespace RM.Core;

public class AutoRefresher {
  #region Events -------------------------------------------------------------
  public event Action? OnStateChanged;
  #endregion

  #region Variables ----------------------------------------------------------
  private int _interval;
  private System.Timers.Timer? _timer = new(10000);
  private bool _isRunning;
  private Folders _folders;
  #endregion

  #region Constructor --------------------------------------------------------
  public AutoRefresher(Folders folders, int interval = 10000) {
    _folders = folders;
    _interval = interval;
    _isRunning = false;
  }
  #endregion

  #region Interface ----------------------------------------------------------
  public void Start() {
    if (_isRunning) return;
    Task.Run(Run);
    _isRunning = true;
    _timer = new System.Timers.Timer(_interval);
    _timer.Elapsed += (sender, e) => Common.RunInBackground(Run)((s, e) => OnStateChanged?.Invoke());
    _timer.Start();
  }

  public void Stop() {
    if (!_isRunning) return;
    _isRunning = false;
    _timer?.Stop();
    _timer?.Dispose();
    _timer = null;
  }
  public void SetInterval(int interval) {
    _interval = interval;
    if (_timer != null) {
      _timer.Interval = _interval;
    }
  }
  #endregion

  #region Implementation -----------------------------------------------------
  private void Run() {
    _timer?.Stop();
    _folders.Analyze();
    _timer?.Start();
  }
  #endregion
}
