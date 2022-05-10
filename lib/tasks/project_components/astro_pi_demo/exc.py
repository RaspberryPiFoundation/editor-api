class GPIOZeroError(Exception):
    "Base class for all exceptions in GPIO Zero"

class GPIODeviceError(GPIOZeroError):
    "Base class for errors specific to the GPIODevice hierarchy"

class GPIOPinInUse(GPIODeviceError):
    "Error raised when attempting to use a pin already in use by another device"
