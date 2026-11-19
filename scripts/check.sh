#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
mkdir -p .build
swiftc Sources/SnakeCore/GameEngine.swift Tests/SnakeCoreTests/GameEngineTests.swift -o .build/rule-checks
.build/rule-checks
