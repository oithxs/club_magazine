# ここにpdf化したいmarkdownが含まれるディレクトリを指定してください
MD_DIRS:=

# 以下触らないこと
OUTDIR:=build
TEX_FILES:=$(foreach dir, $(MD_DIRS), $(OUTDIR)/$(dir).tex)
HTML_FILES:=$(foreach dir, $(MD_DIRS), $(OUTDIR)/$(dir).html)
ALL_MD_FILES:=$(foreach dir, $(MD_DIRS), $(sort $(wildcard $(dir)/*.md)))
TARGET:=main.pdf


PWD=$(shell pwd)
NB_UID=$(shell id -u)
NB_GID=$(shell id -g)

define RUN
	docker-compose run --user=root --rm -v $(PWD):/home/user/work -e NB_UID=$(NB_UID) -e NB_GID=$(NB_GID) $1 $2
endef

GET_DIR_NAME=$(patsubst %/,%,$(word 1, $(dir $1)))

all: textlint tex html pdf

textlint: $(ALL_MD_FILES)
	textlint -f unix $(ALL_MD_FILES)

textlint-fix: $(ALL_MD_FILES)
	textlint --fix $(ALL_MD_FILES)

textlint-diff:
	textlint --fix --dry-run --format diff $(ALL_MD_FILES)

$(OUTDIR)/%.tex: %/*
	mkdir -p $(OUTDIR)
	$(eval DIR_NAME=$(call GET_DIR_NAME,$^))

	$(eval MD_FILES=$(sort $(wildcard $(DIR_NAME)/*.md)))

	$(eval BIB_FILE=$(DIR_NAME)/$(DIR_NAME).bib)
	$(eval CITE_OPTION=$(shell if [ -f $(BIB_FILE) ]; then echo --bibliography=$(BIB_FILE); else echo ; fi))

	pandoc $(MD_FILES) $(CITE_OPTION) --filter pandoc-crossref -M "crossrefYaml=crossref-config.yaml" -o $@

tex: $(TEX_FILES)

pdf: $(TEX_FILES)
	ptex2pdf -l -ot -kanji=utf8 main
	ptex2pdf -l -ot -kanji=utf8 main


$(OUTDIR)/%.html: %/*
	mkdir -p $(OUTDIR)
	$(eval DIR_NAME=$(call GET_DIR_NAME,$^))

	$(eval MD_FILES=$(sort $(wildcard $(DIR_NAME)/*.md)))

	$(eval BIB_FILE=$(DIR_NAME)/$(DIR_NAME).bib)
	$(eval CITE_OPTION=$(shell if [ -f $(BIB_FILE) ]; then echo --bibliography=$(BIB_FILE); else echo ; fi))

	pandoc $(MD_FILES) $(CITE_OPTION) --filter pandoc-crossref -M "crossrefYaml=crossref-config.yaml" -o $@

html: $(HTML_FILES)

docker-build:
	docker-compose build base
	docker-compose build pandoc texlive textlint

docker-pull:
	docker-compose pull

docker-all: docker-textlint docker-tex docker-html docker-pdf

docker-textlint:
	$(call RUN,textlint,make textlint)

docker-textlint-fix:
	$(call RUN,textlint,make textlint-fix)

docker-textlint-diff:
	$(call RUN,textlint,make textlint-diff)

docker-tex:
	$(call RUN,pandoc,make tex)

docker-html:
	$(call RUN,pandoc,make html)

docker-pdf:
	$(call RUN,texlive,make pdf)


clean:
	- rm -rf main.bbl main.aux main.blg main.bcf main.log main.dvi main.pdf main.run.xml	
	- rm -rf $(TARGET)
	- rm -rf $(OUTDIR)

.PHONY:
	docker-build docker-pull
	docker-all docker-tex docker-html docker-pdf
	all tex pdf html clean
