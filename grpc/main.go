// main.go
package main

import (
	"encoding/json"
	"net/http"
)

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
	json.NewEncoder(w).Encode(resp)
}

func main() {
	http.HandleFunc("/process", handler)
	http.ListenAndServe(":8000", nil)
}
