#!/usr/bin/env python

# Copyright (c) IPython Development Team.
# Distributed under the terms of the Modified BSD License.

import sys
import re
from glob import glob
import os
import shutil

from setuptools import setup
from setuptools.command.bdist_egg import bdist_egg

# the name of the package
name = 'yapkernel'


class bdist_egg_disabled(bdist_egg):
    """Disabled version of bdist_egg

    Prevents setup.py install from performing setuptools' default easy_install,
    which it should never ever do.
    """
    def run(self):
        sys.exit("Aborting implicit building of eggs. Use `pip install .` to install from source.")


pjoin = os.path.join
here = os.path.abspath(os.path.dirname(__file__))
pkg_root = pjoin(here, name)

packages = ['yapkernel']
for d, _, _ in os.walk(pjoin(here, name)):
    if os.path.exists(pjoin(d, '__init__.py')):
        packages.append(d[len(here)+1:].replace(os.path.sep, '.'))

package_data = {
    'yapkernel': ['resources/*.*'],
}

with open(pjoin(here, 'README.md')) as fid:
    LONG_DESCRIPTION = fid.read()

setup_args = dict(
    name=name,
    cmdclass={
        'bdist_egg': bdist_egg if 'bdist_egg' in sys.argv else bdist_egg_disabled,
    },
    scripts=glob(pjoin('scripts', '*')),
    packages=packages,
    py_modules=['yapkernel_launcher'],
    package_data=package_data,
    description="IPython Kernel for Jupyter",
    long_description_content_type="text/markdown",
    author='IPython Development Team',
    author_email='ipython-dev@scipy.org',
    url='https://ipython.org',
    license='BSD',
    long_description=LONG_DESCRIPTION,
    platforms="Linux, Mac OS X, Windows",
    keywords=['Interactive', 'Interpreter', 'Shell', 'Web'],
    python_requires='>=3.7',
    install_requires=[
        "ipython_genutils",
        'importlib-metadata<5;python_version<"3.8.0"',
        'argcomplete>=1.12.3;python_version<"3.8.0"',
        'debugpy>=1.0.0,<2.0',
        'ipython>=7.23.1,<8.0',
        'traitlets>=4.1.0,<6.0',
        'jupyter_client<8.0',
        'tornado>=4.2,<7.0',
        'matplotlib-inline>=0.1.0,<0.2.0',
        'appnope;platform_system=="Darwin"',
    ],
    extras_require={
        "test": [
            "pytest !=5.3.4",
            "pytest-cov",
            "flaky",
            "nose",  # nose because there are still a few nose.tools imports hanging around
            "ipyparallel",
        ],
    },
    classifiers=[
        'Intended Audience :: Developers',
        'Intended Audience :: System Administrators',
        'Intended Audience :: Science/Research',
        'License :: OSI Approved :: BSD License',
        'Programming Language :: Python',
        'Programming Language :: Python :: 3',
    ],
)


if any(a.startswith(('bdist', 'install')) for a in sys.argv):
    sys.path.insert(0, here)
    from yapkernel.kernelspec import write_kernel_spec, make_ipkernel_cmd, KERNEL_NAME

    # When building a wheel, the executable specified in the kernelspec is simply 'python'.
    if any(a.startswith('bdist') for a in sys.argv):
        argv = make_ipkernel_cmd(executable='python')
    # When installing from source, the full `sys.executable` can be used.
    if any(a.startswith('install') for a in sys.argv):
        argv = make_ipkernel_cmd()
    dest = os.path.join(here, 'data_kernelspec')
    if os.path.exists(dest):
        shutil.rmtree(dest)
    write_kernel_spec(dest, overrides={'argv': argv})

    setup_args['data_files'] = [
        (
            pjoin('share', 'jupyter', 'kernels', KERNEL_NAME),
            glob(pjoin('data_kernelspec', '*')),
        )
    ]


if __name__ == '__main__':
    setup(**setup_args)
