#!/bin/bash

# ASCII Banner
banner() {

    echo "========================================="
    echo " ___              ___                   " 
    echo "  |   _  ._  o  _  |  ._  o  _   _ _|_  "
    echo " _|_ (_) | | | (_ _|_ | | | (/_ (_  |_  "
    echo "                         _|             " 
    echo "🔍 Advanced Bug Bounty Injection Scanner"
    echo "       Developed by Narayanan K         "
    echo "========================================="
}

# Display help
show_help() {
    banner
    echo "Usage: $0 --scan <file>"
    echo ""
    echo "Options:"
    echo "  --scan <file>   Scan for vulnerable endpoints using various tools."
    echo "  --help          Show this help message."
    echo ""
    exit 0
}

# Install required tools
install_tools() {
    echo "[*] Installing required tools..."
    
    # Required APT packages
    APT_TOOLS=("git" "curl" "jq" "python3-pip")

    for pkg in "${APT_TOOLS[@]}"; do
        if ! dpkg -s "$pkg" &> /dev/null; then
            echo "[*] Installing $pkg..."
            sudo apt-get install -y "$pkg"
        else
            echo "[✔] $pkg is already installed."
        fi
    done

    # Install pipx if not already installed
    if ! command -v pipx &> /dev/null; then
        echo "[*] Installing pipx..."
        python3 -m pip install --user pipx
        python3 -m pipx ensurepath
        # Reload the shell to ensure pipx is in the PATH
        exec "$SHELL"
    else
        echo "[✔] pipx is already installed."
    fi

    # Install uro using pipx
    if ! command -v uro &> /dev/null; then
        echo "[*] Installing uro..."
        pipx install uro
    else
        echo "[✔] uro is already installed."
    fi

    # Install Go-based tools
    GO_TOOLS=("projectdiscovery/katana/cmd/katana" "tomnomnom/waybackurls" "lc/gau" "hakluke/hakrawler" "KathanP19/Gxss" "tomnomnom/gf")

    for tool in "${GO_TOOLS[@]}"; do
        tool_name=$(basename "$tool")
        if ! command -v "$tool_name" &> /dev/null; then
            echo "[*] Installing $tool_name..."
            go install "github.com/$tool@latest"
        else
            echo "[✔] $tool_name is already installed."
        fi
    done

    # Install loxs
    if [ ! -d "loxs" ]; then
        echo "[*] Installing Loxs..."
        git clone https://github.com/coffinxp/loxs.git
        cd loxs
        python3 -m venv path/to/venv
        source path/to/venv/bin/activate
        pip install --upgrade pip
        pip3 install -r requirements.txt
        cd ..
    else
        echo "[✔] loxs is already installed."
    fi

    echo "[*] All tools installed successfully."
}

# Run the scan
run_scan() {
    local input_file="$1"

    if [ ! -f "$input_file" ]; then
        echo "[!] Error: File '$input_file' not found!"
        exit 1
    fi

    if [ ! -s "$input_file" ]; then
        echo "[!] Error: File '$input_file' is empty!"
        exit 1
    fi

    echo "[*] Starting the scan using '$input_file'..."

    # Step 1: Run Katana
    echo "[*] Running Katana..."
    katana -u "$input_file" -o endpoints-1.txt

    # Step 2: Run waybackurls
    echo "[*] Running waybackurls..."
    cat "$input_file" | waybackurls | grep "=" | tee endpoints-2.txt

    # Step 3: Run gau
    echo "[*] Running gau..."
    cat "$input_file" | gau | tee endpoints-3.txt

    # Step 5: Run hakrawler
    echo "[*] Running hakrawler..."
    cat "$input_file" | hakrawler | tee -a endpoints-4.txt

    # Step 6: Merge all endpoints
    echo "[*] Merging all endpoints..."
    cat endpoints-1.txt endpoints-2.txt endpoints-3.txt endpoints-4.txt | sort -u > endpoints.txt

    # Step 7: Run Filter RXSS
    echo "[*] Running the RXSS filters..."
    mkdir RXSS-Filters
    grep -Ei "(\?|&)(q|search|p|query|s|keyword|term|name|id|user|username|email|message|error|msg|redirect|url|next|return|callback|file|path|dir|action|view|page|sort|order|filter|from|to|date|year|month|day|lang|locale|domain|host|port|protocol|service|mode|type|format|json|xml|feed|rss|category|tag|product|item|cart|checkout|payment|price|amount|currency|ref|reference|source|utm_source|utm_medium|utm_campaign|utm_term|utm_content)=" endpoints.txt > RXSS-Filters/filtered_xss_urls.txt
    cat RXSS-Filters/filtered_xss_urls.txt | uro | tee RXSS-Filters/filtered_xss_uro.txt
    cat RXSS-Filters/filtered_xss_uro.txt | httpx -silent -o RXSS-Filters/final_result_RXSS_🔍.txt
  
    # Step 8: Run Filter LFI
    echo "[*] Running the LFI filters..."
    mkdir LFI-Filters
    grep -Ei "(\?|&)(file|page|include|document|path|folder|directory|template|layout|root|cfg|config|doc|view|read|load|filename|download)=[^&]*\.\.\/" endpoints.txt > LFI-Filters/filtered_lfi_urls.txt
    cat LFI-Filters/filtered_lfi_urls.txt | uro | tee LFI-Filters/filtered_lfi_uro.txt
    cat LFI-Filters/filtered_lfi_uro.txt | httpx -silent -o LFI-Filters/final_result_LFI_🔍.txt

    # Step 9: Run Filter Open Redirection 
    echo "[*] Running the Open Redirection filters..."
    mkdir OR-Filters
    grep -Ei "(\?|&)(url|redirect|next|target|rurl|dest|destination|return|return_url|returnTo|redirect_uri|redirect_url|redirect_to|forward|forward_url|forward_to|link|out|view|file|page|go|checkout|continue|callback)=[^&]*(https?:\/\/|www\.|\.)[^&]*" endpoints.txt > OR-Filters/filtered_or_urls.txt
    cat OR-Filters/filtered_or_urls.txt | uro | tee OR-Filters/filtered_or_uro.txt
    cat OR-Filters/filtered_or_uro.txt | httpx -silent -o OR-Filters/final_result_OR_🔍.txt

    # Step 10: Run Filter 
    echo "[*] Running the SQLI filters..."
    mkdir SQLI-Filters
    grep -Ei "(\?|&)(id|username|password|search|query|name|email|user|account|order|sort|limit|offset|from|to|date|year|month|day|lang|locale|domain|host|port|protocol|service|mode|type|format|json|xml|feed|rss|category|tag|product|item|cart|checkout|payment|price|amount|currency|ref|reference|source|utm_source|utm_medium|utm_campaign|utm_term|utm_content)=[^&]*('|\"|%27|%22|%2527|%2522|\+OR\+|\+AND\+|\+UNION\+|\+SELECT\+|\+FROM\+|\+WHERE\+|\+LIKE\+|\+LIMIT\+|\+OFFSET\+|\+ORDER\+BY\+|\+GROUP\+BY\+|\+HAVING\+|\+JOIN\+|\+INTO\+|\+VALUES\+|\+UPDATE\+|\+DELETE\+|\+INSERT\+|\+CREATE\+|\+ALTER\+|\+DROP\+|\+TRUNCATE\+|\+RENAME\+|\+EXEC\+|\+DECLARE\+|\+CASE\+|\+WHEN\+|\+THEN\+|\+ELSE\+|\+END\+|\+IF\+|\+NULL\+|\+NOT\+|\+BETWEEN\+|\+EXISTS\+|\+IN\+|\+IS\+|\+AS\+|\+ON\+|\+USING\+|\+DISTINCT\+|\+ALL\+|\+ANY\+|\+SOME\+|\+UNIQUE\+|\+PRIMARY\+|\+FOREIGN\+|\+KEY\+|\+CHECK\+|\+DEFAULT\+|\+INDEX\+|\+VIEW\+|\+PROCEDURE\+|\+FUNCTION\+|\+TRIGGER\+|\+CURSOR\+|\+FETCH\+|\+OPEN\+|\+CLOSE\+|\+DEALLOCATE\+|\+PREPARE\+|\+EXECUTE\+|\+DESCRIBE\+|\+EXPLAIN\+|\+SHOW\+|\+USE\+|\+SET\+|\+BEGIN\+|\+COMMIT\+|\+ROLLBACK\+|\+SAVEPOINT\+|\+RELEASE\+|\+LOCK\+|\+UNLOCK\+|\+GRANT\+|\+REVOKE\+|\+DENY\+|\+BACKUP\+|\+RESTORE\+|\+LOAD\+|\+IMPORT\+|\+EXPORT\+|\+COPY\+|\+ANALYZE\+|\+OPTIMIZE\+|\+REPAIR\+|\+CHECKSUM\+|\+CHECKTABLE\+|\+REPAIRTABLE\+|\+BACKUPTABLE\+|\+RESTORETABLE\+|\+LOADTABLE\+|\+IMPORTTABLE\+|\+EXPORTTABLE\+|\+COPYTABLE\+|\+ANALYZETABLE\+|\+OPTIMIZETABLE\+|\+REPAIRTABLE\+|\+CHECKSUMTABLE\+|\+CHECKTABLETABLE\+|\+REPAIRTABLETABLE\+|\+BACKUPTABLETABLE\+|\+RESTORETABLETABLE\+|\+LOADTABLETABLE\+|\+IMPORTTABLETABLE\+|\+EXPORTTABLETABLE\+|\+COPYTABLETABLE\+|\+ANALYZETABLETABLE\+|\+OPTIMIZETABLETABLE\+|\+REPAIRTABLETABLE\+|\+CHECKSUMTABLETABLE\+)" endpoints.txt > SQLI-Filters/filtered_sqli_urls.txt
    cat SQLI-Filters/filtered_sqli_urls.txt | uro | tee SQLI-Filters/filtered_sqli_uro.txt
    cat SQLI-Filters/filtered_or_uro.txt | httpx -silent -o SQLI-Filters/final_result_sqli_🔍.txt

    # Step 9: Run loxs
    echo "[*] Running loxs"
    cd loxs
    python3 -m venv path/to/venv
    source path/to/venv/bin/activate
    python3 loxs.py
    
    echo "[*] Scan completed. Results saved in 'xsstrike-results.txt'."
}

# Main script logic
if [[ $# -eq 0 ]]; then
    echo "[!] Error: No arguments provided."
    show_help
fi

case "$1" in
    --help)
        show_help
        ;;
    --scan)
        if [ -z "$2" ]; then
            echo "[!] Error: Missing file argument for --scan."
            exit 1
        fi
        install_tools
        run_scan "$2"
        ;;
    *)
        echo "[!] Error: Invalid argument '$1'."
        show_help
        ;;
esac