[中文](README-zh.md) | [English](README.md)

# Discord Multi-Instance Manager

This is a Windows Batch Script (.bat) tool designed to simplify the process of managing multiple Discord accounts. It features a fast, single-screen "Dashboard" interface that allows you to see all your profiles at a glance and act on them with simple, single-key commands.

---

## New "Dashboard" Workflow

This version introduces a completely redesigned, more efficient workflow:

1.  **Launch the Script**: The manager immediately displays a numbered list of all your existing instances.
2.  **Select an Instance**: Enter the **number** of the instance you wish to manage.
3.  **Act with Single Keys**: This takes you to a dedicated action screen for that instance, where you can use simple commands:
    - `L` to **Launch** the instance.
    - `M` to **Modify** (rename) the instance.
    - `T` to **Toggle** Developer Tools on or off.
    - `D` to **Delete** the instance.
    - `B` to go **Back** to the main instance list.
4.  **Top-Level Commands**: From the main list, you can also:
    - `C` to **Create** a new instance.
    - `Q` to **Quit** the manager.

This new model is much faster and removes the need to navigate through multiple menus.

## Features

- **Safe Deletion**: Before deleting an instance, the script now checks if Discord is running. If it is, it will prompt you to force-kill the processes to ensure the deletion can succeed without errors.
- **Dashboard View**: See all your instances in one place right from the start.
- **Single-Key Actions**: Manage selected instances with fast, intuitive commands (`L`, `M`, `T`, `D`).
- **Instance Status Display**: The action screen for each instance clearly shows its full path and whether Developer Tools are currently enabled.
- **Full Instance Management**:
    - **Create**: Create new, isolated instances with custom names.
    - **Launch**: Launch any instance independently.
    - **Rename & Delete**: Full control over instance lifecycle.
    - **Smart DevTools Toggle**: Easily switch DevTools on or off for debugging or customization.

## How to Use

1.  **Save the Script**: Save the code as `manage_discord.bat` (English version) or `manage_discord_zh-TW.bat` (Traditional Chinese version) on your computer.
2.  **Run the Script**: Double-click the `.bat` file to open the dashboard.
3.  **Follow On-Screen Commands**: Enter a number to select an instance or a letter to perform an action.

## Important Notes

- The script creates a `profiles` folder within your Discord's local data directory (`%LOCALAPPDATA%\Discord\`) to store all instance data.
- **Deleting an instance is a permanent action**. It will remove all login information, settings, and cache for that instance. Please be certain before confirming deletion.

---