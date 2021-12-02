"""
This file has the following intentional lint errors
 - import order of typing.Optional
 - single quotes used instead of double quotes
 - main() has no return type
"""
import os

from typing import Optional

def main(arg: Optional[str] = 'hi'):
    print('foobar')


if __name__ == '__main__':
    main()
