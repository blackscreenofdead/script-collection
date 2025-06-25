# 📄 csv_to_code

A small shell script to convert simple CSV files into structured code blocks – perfect for generating repetitive configurations like Terraform modules, firewall rules, or infrastructure docs.

---

## 🧰 Features

- Parses CSV files with `name;ip` structure
- Outputs formatted code blocks (e.g. Terraform modules)
- Easily customizable output template
- Outputs to `output.txt`

---

## 📥 Input Format

CSV file (`test.csv`):
<details>
<summary>Click to show example output</summary>
'''
  module "hello" {
    source    = "git::https://gitlab.XXXX.com/terradorm/module.example.git?ref=1.0.0"
    name      = "hello"
    subnet    = "123"
    vdomparam = "vdom01"
  }

  module "bye" {
    source    = "git::https://gitlab.XXXX.com/terradorm/module.example.git?ref=1.0.0"
    name      = "bye"
    subnet    = "321"
    vdomparam = "vdom01"
  }

'''
</details>
