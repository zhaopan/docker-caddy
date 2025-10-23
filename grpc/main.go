// main.go
package main

import (
    "encoding/json"
    "fmt"
    "net/http"
    "os"
)

// PORT 编译时变量，可以通过 -ldflags "-X main.PORT=8001" 设置
var PORT = "8000"

type Request struct {
    Input string `json:"input"`
}

type Response struct {
    Result  string `json:"result"`
    Details string `json:"details"`
}

func handler(w http.ResponseWriter, r *http.Request) {
    var req Request
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }

    // 业务逻辑处理
    resp := Response{
        Result:  "Processed: " + req.Input,
        Details: "Handled by Go service",
    }

    w.Header().Set("Content-Type", "application/json")
    err := json.NewEncoder(w).Encode(resp)
    if err != nil {
        return
    }
}

func main() {
    // 从环境变量或编译时变量获取端口
    port := os.Getenv("PORT")
    if port == "" {
        port = PORT
    }

    fmt.Printf("gRPC 服务启动在端口 %s\n", port)
    fmt.Printf("API 端点: http://localhost:%s/process\n", port)

    http.HandleFunc("/process", handler)
    http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        _, err := w.Write([]byte("OK"))
        if err != nil {
            return
        }
    })

    if err := http.ListenAndServe(":"+port, nil); err != nil {
        fmt.Printf("服务启动失败: %v\n", err)
        os.Exit(1)
    }
}
