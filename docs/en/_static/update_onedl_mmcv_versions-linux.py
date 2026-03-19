import json
import os
import re

import requests
from bs4 import BeautifulSoup

BASE_URL = 'https://mmwheels.onedl.ai/'
VERSION_JSON_PATH = os.path.join(os.path.dirname(__file__), 'version.json')

# Regex to extract cuda/torch from folder name, e.g. cuda121-torch240
FOLDER_RE = re.compile(r'^/(cu\d+|cpu|jetpach\d+)-torch(\d+)(?=/simple$)')
# Regex to extract version (semantic/PEP440) and python tag from wheel filename
WHEEL_RE = re.compile(
    r'onedl_mmcv-(?P<version>\d+\.\d+\.\d+(?:[a-zA-Z]+\d+)?(?:\.post\d+)?(?:\.dev\d+)?)-cp(?P<pyver>\d+)-cp\d+-.*.whl'  # noqa: E501
)


def get_index_links(url):
    resp = requests.get(url)
    resp.raise_for_status()
    soup = BeautifulSoup(resp.text, 'html.parser')
    return [
        a['href'].rstrip('/') for a in soup.find_all('a', href=True)
        if a['href'] != '../'
    ]


def torch_version_str(torch_digits):
    # torch240 -> 2.4.x, torch250 -> 2.5.x, torch281 -> 2.8.x,
    # torch2100 -> 2.10.0
    if len(torch_digits) == 3:
        return f'{torch_digits[0]}.{torch_digits[1]}.x'
    elif len(torch_digits) == 4:
        return f'{torch_digits[0]}.{torch_digits[1:3]}.{torch_digits[3]}'
    else:
        return torch_digits


def cuda_version_str(cuda_str):
    # cuda124 -> 12.4, cpu -> cpu
    if cuda_str == 'cpu':
        return 'cpu'
    if cuda_str.startswith('cu'):
        digits = cuda_str[2:]
        if len(digits) == 3:
            return f'{digits[0:2]}.{digits[2]}'
        elif len(digits) == 2:
            return f'{digits[0]}.{digits[1]}'
        else:
            return digits
    if cuda_str.startswith('jetpack'):
        digits = cuda_str[7:]
        if len(digits) == 3:
            return f'{digits[0:2]}.{digits[2]}'
        elif len(digits) == 2:
            return f'{digits[0]}.{digits[1]}'
        else:
            return digits
    return cuda_str


def main():
    print('Fetching index from:', BASE_URL)
    combos = {}
    # Get all cuda/torch folders
    folders = get_index_links(BASE_URL)
    for folder in folders:
        m = FOLDER_RE.match(folder)
        if not m:
            continue
        cuda, torch = m.groups()
        # Go to simple/onedl-mmcv/ under this folder
        wheel_index_url = f'{BASE_URL}{folder}/onedl-mmcv/'
        try:
            wheels = get_index_links(wheel_index_url)
        except Exception as e:
            print(f'Failed to fetch {wheel_index_url}: {e}')
            continue
        for wheel in wheels:
            # Only process .whl files
            if not wheel.endswith('.whl'):
                continue
            whl_match = WHEEL_RE.search(wheel)
            if not whl_match:
                continue
            version = whl_match.group('version')
            combos.setdefault(cuda, {}).setdefault(torch, set()).add(version)

    # Compose Linux section for version.json
    linux_section = []
    for cuda, torch_dict in combos.items():
        for torch, versions in torch_dict.items():
            linux_section.append({
                'cuda':
                cuda_version_str(cuda),
                'torch':
                torch_version_str(torch),
                'mmcv':
                sorted(
                    versions,
                    key=lambda v: [
                        int(x) if x.isdigit() else x
                        for x in re.split(r'(\d+)', v)
                    ])
            })

    # Load version.json
    if os.path.exists(VERSION_JSON_PATH):
        with open(VERSION_JSON_PATH, encoding='utf-8') as f:
            version_json = json.load(f)
    else:
        version_json = {'Linux': [], 'Windows': [], 'macOS': []}

    version_json['Linux'] = linux_section
    # pprint(linux_section)

    # Write back to version.json
    with open(VERSION_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(version_json, f, indent=4, ensure_ascii=False)
    print(f'Updated {VERSION_JSON_PATH} with {len(linux_section)} combos.')


if __name__ == '__main__':
    main()
