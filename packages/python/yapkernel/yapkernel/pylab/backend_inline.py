"""A matplotlib backend for publishing figures via display_data"""

# Copyright (c) IPython Development Team.
# Distributed under the terms of the Modified BSD License.

import warnings

from matplotlib_inline.backend_inline import *  # analysis: ignore # noqa F401


warnings.warn(
    "`yapkernel.pylab.backend_inline` is deprecated, directly "
    "use `matplotlib_inline.backend_inline`",
    DeprecationWarning
)
