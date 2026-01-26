package main

import (
	"crypto/tls"
	"flag"
	"fmt"
	"io"
	"net/http"
	"runtime"
	"sync"
	"time"
)

func main() {
	// 强制使用所有 CPU 核心
	runtime.GOMAXPROCS(runtime.NumCPU())

	url := flag.String("u", "http://localhost", "测试 URL")
	count := flag.Int("n", 100, "测试总次数")
	workers := flag.Int("c", 10, "并发数")
	interval := flag.Int("i", 10, "每隔多少次输出一次日志")
	insecure := flag.Bool("k", true, "忽略 SSL 证书验证")
	flag.Parse()

	// 核心优化：极致自定义 Transport
	tr := &http.Transport{
		TLSClientConfig:     &tls.Config{InsecureSkipVerify: *insecure},
		MaxIdleConns:        *workers * 2,
		MaxIdleConnsPerHost: *workers,
		MaxConnsPerHost:     *workers * 2,
		IdleConnTimeout:     2 * time.Minute,
		DisableKeepAlives:   false,
		// 跳过 Expect: 100-continue 握手
		ExpectContinueTimeout: 0,
	}
	client := &http.Client{
		Transport: tr,
		Timeout:   15 * time.Second,
	}

	fmt.Printf("CPU 核心: %d | 调度核心: %v\n", runtime.NumCPU(), runtime.GOMAXPROCS(0))
	fmt.Printf("压榨模式: [排水复用=ON] [延迟日志=ON] [TCP-KeepAlive=ON]\n")
	fmt.Printf("并发: %d | 目标: %s\n", *workers, *url)

	start := time.Now()
	var wg sync.WaitGroup
	results := make(chan bool, *count)
	jobs := make(chan int, *count)

	// 启动工作线程 (Worker Pool)
	for w := 1; w <= *workers; w++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			for j := range jobs {
				resp, err := client.Get(*url)
				success := false
				if err != nil {
					if *interval > 0 && j%*interval == 0 {
						fmt.Printf("[失败] Worker %d | 任务 %d: %v\n", id, j, err)
					}
					results <- false
					continue
				}

				// 压榨核心：只有读完 Body，连接才能被 100% 复用
				_, _ = io.Copy(io.Discard, resp.Body)
				success = resp.StatusCode == http.StatusOK

				// 极致优化：只有在需要打印时才进行字符串格式化和打印
				if *interval > 0 && j%*interval == 0 {
					status := "成功"
					if !success {
						status = "异常"
					}
					fmt.Printf("[%s] Worker %d | 任务 %d: 状态码 %d\n", status, id, j, resp.StatusCode)
				}

				resp.Body.Close()
				results <- success
			}
		}(w)
	}

	// 分发任务
	go func() {
		for i := 0; i < *count; i++ {
			jobs <- i
		}
		close(jobs)
	}()

	// 等待完成
	go func() {
		wg.Wait()
		close(results)
	}()

	success := 0
	failure := 0
	for res := range results {
		if res {
			success++
		} else {
			failure++
		}
	}

	duration := time.Since(start)
	fmt.Printf("\n测试完成!\n")
	fmt.Printf("耗时: %v\n", duration)
	fmt.Printf("成功: %d, 失败: %d\n", success, failure)
	if duration.Seconds() > 0 {
		fmt.Printf("QPS: %.2f\n", float64(success+failure)/duration.Seconds())
	}
}
