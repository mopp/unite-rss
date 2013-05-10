scriptencoding utf-8


let s:save_cpo = &cpo
set cpo&vim


let g:unite_source_rss_url_dict = {
            \ '暗黒美夢王の間' : 'http://vinarian.blogspot.jp/rss.xml',
            \ 'Big Sky' : 'http://mattn.kaoriya.net/index.rss',
            \ 'もぷろぐ' : 'http://ac-mopp.blogspot.jp/rss.xml',
            \ }

let s:load_target = []

let s:beSource = {
            \ 'name' : 'rss',
            \ 'action_table': {},
            \ 'default_action': {'uri': 'open'},
            \ }



" define unite source
function! unite#sources#read_rss#define()
    return s:beSource
endfunction


" define unite action
let s:beSource.action_table.open = { 'description': 'open selected article in buffer' }
function! s:beSource.action_table.open.func(arg)
    " あれば削除
    if 0 != bufexists('RSS_ARTICLE')
        silent exe 'bdelete! RSS_ARTICLE'
    endif

    silent exe 'vertical botright split edit'
    silent file BATTLE_EDITORS

    " バッファへ書き込み
    call append(0, s:align_article(a:arg.action__source_args[0]))
    call cursor(1, 1)

    " 設定値変更
    setlocal fileformat=unix buftype=nofile filetype=text wrap nomodifiable 
    silent! %foldopen
endfunction


" generate unite candidates
function! s:beSource.gather_candidates(args, context)
    let items = []

    if len(a:args) == 0
        " 初回のunite source
        for key in keys(g:unite_source_rss_url_dict)
            call add(items, {
                        \ 'word': key,
                        \ 'abbr': key,
                        \ 'kind': 'source',
                        \ 'action__source_args': [key],
                        \ 'action__source_name': 'rss',
                        \})
        endfor
    elseif has_key(g:unite_source_rss_url_dict, a:args[0])
        " 設定したサイト名から判別
        " 記事一覧を返す
        for article in s:get_plane_article_date(g:unite_source_rss_url_dict[a:args[0]])
            call add(items, {
                        \ 'word': article.title,
                        \ 'abbr': article.title,
                        \ 'kind': 'uri',
                        \ 'action__source_args': [ article ],
                        \ 'action__path': article.link,
                        \ 'source': 'rss',
                        \ })
        endfor
        let s:load_target = deepcopy(items)
    endif

    return items
endfunction


" utils
function! s:get_plane_article_date(url)
    let articles = []

    " item の key は id, link, date, title, content
    for item in webapi#feed#parseURL(a:url)
        call add(articles, map(item, "substitute(v:val, '　', '  ', 'g')"))
    endfor

    return articles
endfunction


function! s:align_article(artDict)
    let cleaned = substitute(a:artDict.content, '<\/\=\(br\)\@![^><]*>', '', 'g')
    let splited = split(cleaned, '<br[^>]*>')
    return map(splited, 'webapi#html#decodeEntityReference(v:val)')
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
