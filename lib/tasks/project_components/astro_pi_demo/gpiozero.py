import _internal_sense_hat as _ish
from exc import GPIOPinInUse

class MotionSensor(object):

    inst = False

    def __init__(self, pull_up=False, active_state=None, queue_len=1, sample_rate=10, threshold=0.5, partial=False, pin_factory=None):
        if MotionSensor.inst:
            raise GPIOPinInUse()
        self._pin = 12
        self.when_motion = None
        self.when_no_motion = None
        MotionSensor.inst = True

    def wait_for_motion(self, timeout=None):
        _ish._waitmotion(timeout, True)

    def wait_for_no_motion(self, timeout=None):
        _ish._waitmotion(timeout, False)

    @property
    def motion_detected(self):
        return _ish.motionRead() == 1

    @property
    def pin(self):
        pass

    @property
    def value(self):
        return _ish.motionRead()

    @property
    def when_motion(self):
        return self._when_motion

    @when_motion.setter
    def when_motion(self, value):
        self._when_motion = value
        _ish._start_motion(value)

    @property
    def when_no_motion(self):
        return self._when_no_motion

    @when_no_motion.setter
    def when_no_motion(self, value):
        self._when_no_motion = value
        _ish._stop_motion(value)
