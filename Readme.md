# Advanced Bug Bounty Injection Scanner 🔍

The **Advanced Bug Bounty Injection Scanner** is a powerful Bash script designed to automate the process of discovering and scanning vulnerable endpoints in web applications. It integrates multiple tools and techniques to detect common vulnerabilities such as **XSS**, **LFI**, **Open Redirection**, and **SQL Injection**. Developed by **Narayanan K**, this tool is a must-have for bug bounty hunters, penetration testers, and security researchers.

---

## Features ✨

- **Multi-Tool Integration**: Combines tools like **Katana**, **waybackurls**, **gau**, **hakrawler**, and more for comprehensive endpoint discovery.
- **Vulnerability Filters**: Automatically filters endpoints for potential vulnerabilities like **XSS**, **LFI**, **Open Redirection**, and **SQL Injection**.
- **Easy to Use**: Simple command-line interface with clear instructions.
- **Customizable**: Easily extendable with additional tools or filters.

---

## Installation 🛠️

### Prerequisites

- **Linux-based OS** (preferably Ubuntu/Debian)
- **Git**, **Curl**, **Python3**, **Pip**, **Go**, and other basic tools.

### Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/Narayanan-info/IonicInject.git
   cd IonicInject
   ```

2. Make the script executable:
    ```bash
    chmod +x IonicInject.sh
    ```

3. Run the script with the --scan option to install dependencies and start scanning:
    ```bash
    ./IonicInject.sh --scan targets.txt
    ```

