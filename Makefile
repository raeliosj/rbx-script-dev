# Variables
OUTPUT_FILE := ./output/bundle.lua
INPUT_FILE := ./grow-a-garden/main.lua
RELEASE_FILE := ./output/bundle-release.lua

OUTPUT_FILE_FISH := ./output/bundle-fish.lua
INPUT_FILE_FISH := ./fish-it/main.lua
RELEASE_FILE_FISH := ./output/bundle-fish-release.lua

.PHONY: run-gag
run-gag: 
	@if [ -f "$(INPUT_FILE)" ]; then \
		lua-bundler -e $(INPUT_FILE) -o $(OUTPUT_FILE); \
		echo "$(GREEN)Copying output file to clipboard...$(NC)"; \
		if [ -f "$(OUTPUT_FILE)" ]; then \
			if command -v xclip >/dev/null 2>&1; then \
				cat "$(OUTPUT_FILE)" | xclip -selection clipboard; \
				echo "$(GREEN)✓ Content copied to clipboard using xclip!$(NC)"; \
			elif command -v xsel >/dev/null 2>&1; then \
				cat "$(OUTPUT_FILE)" | xsel --clipboard --input; \
				echo "$(GREEN)✓ Content copied to clipboard using xsel!$(NC)"; \
			elif command -v wl-copy >/dev/null 2>&1; then \
				cat "$(OUTPUT_FILE)" | wl-copy; \
				echo "$(GREEN)✓ Content copied to clipboard using wl-copy (Wayland)!$(NC)"; \
			else \
				echo "$(RED)No clipboard tool found! Please install xclip, xsel, or wl-copy$(NC)"; \
				echo "$(YELLOW)Install with: sudo apt-get install xclip$(NC)"; \
			fi; \
		else \
			echo "$(RED)Output file $(OUTPUT_FILE) not found!$(NC)"; \
		fi; \
	else \
		echo "$(RED)Entry file $(INPUT_FILE) not found!$(NC)"; \
		exit 1; \
	fi

.PHONY: release
release:
	@lua-bundler -e $(INPUT_FILE) -o $(RELEASE_FILE) --release --obfuscate 3
	@echo "$(GREEN)Copying output file to clipboard...$(NC)"; \
	if [ -f "$(RELEASE_FILE)" ]; then \
		if command -v xclip >/dev/null 2>&1; then \
			cat "$(RELEASE_FILE)" | xclip -selection clipboard; \
			echo "$(GREEN)✓ Content copied to clipboard using xclip!$(NC)"; \
		elif command -v xsel >/dev/null 2>&1; then \
			cat "$(RELEASE_FILE)" | xsel --clipboard --input; \
			echo "$(GREEN)✓ Content copied to clipboard using xsel!$(NC)"; \
		elif command -v wl-copy >/dev/null 2>&1; then \
			cat "$(RELEASE_FILE)" | wl-copy; \
			echo "$(GREEN)✓ Content copied to clipboard using wl-copy (Wayland)!$(NC)"; \
		else \
			echo "$(RED)No clipboard tool found! Please install xclip, xsel, or wl-copy$(NC)"; \
			echo "$(YELLOW)Install with: sudo apt-get install xclip$(NC)"; \
		fi; \
	else \
		echo "$(RED)Output file $(RELEASE_FILE) not found!$(NC)"; \
	fi;

.PHONY: run-fish
run-fish: 
	@if [ -f "$(INPUT_FILE_FISH)" ]; then \
		lua-bundler -e $(INPUT_FILE_FISH) -o $(OUTPUT_FILE_FISH); \
		echo "$(GREEN)Copying output file to clipboard...$(NC)"; \
		if [ -f "$(OUTPUT_FILE_FISH)" ]; then \
			if command -v xclip >/dev/null 2>&1; then \
				cat "$(OUTPUT_FILE_FISH)" | xclip -selection clipboard; \
				echo "$(GREEN)✓ Content copied to clipboard using xclip!$(NC)"; \
			elif command -v xsel >/dev/null 2>&1; then \
				cat "$(OUTPUT_FILE_FISH)" | xsel --clipboard --input; \
				echo "$(GREEN)✓ Content copied to clipboard using xsel!$(NC)"; \
			elif command -v wl-copy >/dev/null 2>&1; then \
				cat "$(OUTPUT_FILE_FISH)" | wl-copy; \
				echo "$(GREEN)✓ Content copied to clipboard using wl-copy (Wayland)!$(NC)"; \
			else \
				echo "$(RED)No clipboard tool found! Please install xclip, xsel, or wl-copy$(NC)"; \
				echo "$(YELLOW)Install with: sudo apt-get install xclip$(NC)"; \
			fi; \
		else \
			echo "$(RED)Output file $(OUTPUT_FILE_FISH) not found!$(NC)"; \
		fi; \
	else \
		echo "$(RED)Entry file $(INPUT_FILE_FISH) not found!$(NC)"; \
		exit 1; \
	fi