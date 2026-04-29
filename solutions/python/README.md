# Python 参考解答

此目录收录从 `careercup/CtCI-6th-Edition-Python` 整理进本仓库的 Python 参考解答。

- 上游仓库：`git@github.com:careercup/CtCI-6th-Edition-Python.git`
- 当前整理基准：`653e50c`

收录原则：

- 尽量保持上游文件名与章节/题号的对应关系。
- 书本章节正文通过 `{{#include ...}}` 内嵌这些源码，避免重复维护两份内容。
- 若某题依赖共用 helper，会一并收录到同一语言目录下。

运行说明：

- 若需直接运行这些 Python 文件，请从仓库根目录设置 `PYTHONPATH=solutions/python`。
- 示例：`PYTHONPATH=solutions/python python solutions/python/chapter_02/p05_sum_lists.py`
