# Ludusavi Save Helper

A simple Playnite extension to quickly add custom game save paths to your Ludusavi manifest.

## Setup

1. In **Ludusavi** (`OTHER` tab -> `Manifest`), add a new `File` source pointing to your custom `.yaml` manifest and enable it.
2. Install [ludusavi-playnite](https://github.com/mtkennerly/ludusavi-playnite)
3. In **Playnite**, right-click any game -> `Extensions` -> `Ludusavi` -> `Link Unified Manifest File`, and select the `.yaml` file.

## Usage

Right-click the game you want to back up -> `Extensions` -> `Ludusavi` -> `Add Save Path to Manifest`.

Pick the save folder/file, set the wildcard (like `*` or `*.sav`), and you're done. The extension will format everything and append it directly to your rulebook.

You could totally write this .yaml file manually by hand—this extension just automates the tedious writing process and calculates the relative paths (like <winAppData>, <base>) for you. See [ludusavi-manifest](https://github.com/mtkennerly/ludusavi-manifest)
