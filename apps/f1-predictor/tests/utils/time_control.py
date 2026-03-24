"""Time control utilities for testing time-sensitive features."""

from datetime import datetime, timezone, timedelta
from unittest.mock import patch


class TimeController:
    """Control time for testing time-sensitive features.
    
    Usage:
        controller = TimeController()
        controller.freeze(datetime(2026, 3, 23, 14, 0, 0, tzinfo=timezone.utc))
        # ... run test ...
        controller.advance(minutes=10)
        # ... run test ...
        controller.unfreeze()
    """
    
    def __init__(self):
        self._frozen_time = None
        self._patcher = None
    
    def freeze(self, dt: datetime):
        """Freeze time at specific datetime."""
        self._frozen_time = dt
        if self._patcher:
            self._patcher.stop()
        self._patcher = patch('app._now_utc', return_value=dt)
        self._patcher.start()
    
    def advance(self, minutes: int):
        """Advance frozen time by minutes."""
        if self._frozen_time:
            self._frozen_time += timedelta(minutes=minutes)
            self._patcher.stop()
            self._patcher = patch('app._now_utc', return_value=self._frozen_time)
            self._patcher.start()
    
    def unfreeze(self):
        """Restore normal time."""
        if self._patcher:
            self._patcher.stop()
            self._patcher = None
        self._frozen_time = None
