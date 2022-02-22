package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"strings"

	"github.com/gogf/gf/v2/frame/g"
	"github.com/gogf/gf/v2/net/ghttp"
	"io/ioutil"
)

func errHandle(err error) {
	if err != nil {
		panic(err)
	}
}

func main() {
	s := g.Server()

	fileList, err := ioutil.ReadDir("./books")
	errHandle(err)
	var files []string
	// var bookInfo = make(map[string]string)
	var booksData = make(map[string][]string)
	for _, f := range fileList {
		if !f.IsDir() {
			fileName := f.Name()
			files = append(files, fileName)
		}
	}
	// 12 * 12
	for _, file := range files {
		bookName := "./books/" + file
		fmt.Println(bookName)
		f, err := os.Open(bookName)
		errHandle(err)
		reader := bufio.NewReader(f)
		var lines []string
		var showList []string
		for {
			line, err := reader.ReadString('\n')
			if err != nil || io.EOF == err {
				break
			}
			line = strings.ReplaceAll(line, "，", ",")
			line = strings.ReplaceAll(line, "。", ".")
			line = strings.ReplaceAll(line, "“", "\"")
			line = strings.ReplaceAll(line, "”", "\"")
			line = strings.ReplaceAll(line, "？", "?")
			line = strings.ReplaceAll(line, "！", "!")
			line = strings.ReplaceAll(line, "：", ":")
			line = strings.ReplaceAll(line, "\r", "")
			line = strings.ReplaceAll(line, "\n", "")
			line = strings.ReplaceAll(line, "……", "...")
			line = strings.ReplaceAll(line, "（", "(")
			line = strings.ReplaceAll(line, "）", ")")
			lines = append(lines, line)
		}
		for _, line := range lines {
			runeLine := []rune(line)
			len := len(runeLine)
			if len <= 12 {
				showList = append(showList, string(runeLine))
			} else {
				num := len / 12
				for i := 0; i < num; i++ {
					showList = append(showList, string(runeLine[12*i:12*i+12]))
				}
				showList = append(showList, string(runeLine[12*num:len]))
			}
		}
		booksData[file] = showList
	}
	for _, file := range files {
		s.BindHandler("/"+file+"/{page}", func(r *ghttp.Request) {
			fmt.Printf("URL-%v\n", r.Request.URL.Path)
			res := strings.Split(r.Request.URL.Path, "/")
			bookData := booksData[res[1]]
			page := r.Get("page").Int()
			var startIndex int = 12 * (page - 1)
			var list []string
			if startIndex >= len(bookData) {
				r.Response.Writef("%v\n", "已读完")
				return
			}
			for i := 0; i < 12; i++ {
				if startIndex+i >= len(bookData) {
					break
				}
				list = append(list, bookData[startIndex+i])
			}
			encodeJson, err := json.Marshal(list)
			errHandle(err)
			r.Response.Write(string(encodeJson))
		})
	}

	s.BindHandler("/getBooks", func(r *ghttp.Request) {
		encodeJson, err := json.Marshal(files)
		errHandle(err)
		r.Response.Write(string(encodeJson))
	})
	s.Run()
}
