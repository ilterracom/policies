# ILTERRA Legal & Policies

The official, English-only document library for ILTERRA products. GitHub Pages builds this Jekyll repository from the `release` branch and serves it at [policies.ilterra.com](https://policies.ilterra.com/).

## Published documents

The repository contains Markdown policies for 11 products, plus company-wide policies and provider information. The FinCast Privacy Policy, Terms of Use and Payment Policy are based on documents supplied from `fincast_server/docs/legal/`; the newer Privacy Policy supersedes the older FinCast text previously imported from ilterra.com. FinCast currently has no direct checkout, so its Payment Policy describes App Store billing and requires a separate update before direct sales begin.

Other imported documents are based on their source pages on ilterra.com and link to those pages. The public copies identify the operator by the ILTERRA trading name. Some original texts include their own historical dates; these are part of the imported legal text, not portal metadata. The SkyReg and StealthSafe source pages are bilingual, so their Markdown copies contain the English sections only. The Simetria copy omits a Russian alternate app name. Imported documents do not automatically stay in sync with ilterra.com.

## How publication and history work

Each document has a stable URL, such as `/fincast/privacy/`. Changes become part of the public portal when they are merged into `release` and the GitHub Pages deployment finishes. There are no separate edition or effective-date fields in the portal. Each document links to its history on GitHub, where readers can inspect earlier text and the commits that changed it. A commit timestamp records the commit; it does not necessarily record the exact moment GitHub Pages made the change visible.

Keep work on other branches and merge reviewed changes into `release`. A public GitHub repository exposes those other branches too, even though Pages builds only `release`; keep confidential drafts and secrets elsewhere. For changes that require direct user notice or consent, deliver that notice or obtain that consent through the product as applicable. Publishing a commit alone may not satisfy those requirements.

## Repository structure

```text
index.md                    Home page
_layouts/                   Home, product and document layouts
assets/products/            Product icons by product slug
assets/                     Stylesheet and ILTERRA logo
_templates/product/         Examples excluded from the public site
company/*.md                Company-wide policies
company/provider.md         Operator and contact details linked from product documents
<product-slug>/index.md     Product page
<product-slug>/privacy.md   Current privacy policy
<product-slug>/terms.md     Current terms, when available
<product-slug>/payment.md   Payment policy, when applicable
```

The catalog discovers pages with `layout: product`. A product page discovers documents with the matching `product` field and `layout: document`.

## Add a product

1. Create a working branch from `release`.
2. Copy `_templates/product/index.md` to `new-product/index.md`.
3. Fill in `title`, `description`, `product_id`, `order`, `platforms` and `permalink`.
4. Add the public Markdown documents. If a document still lives only on ilterra.com, add its HTTPS URL under `external_documents` instead.
5. Run `ruby scripts/check_content.rb`, review the rendered pages, then merge through a pull request into `release`.

Use a short lowercase `product_id` such as `lumev` or `stealthsafe`. Its product page URL must be `/<product_id>/`.

### Product icons

Six products currently have icons: FinCast, LingoLoop, Lumev, SkyReg, StealthSafe and WebArchive. They are stored at `assets/products/<product_id>/icon.jpg` or `icon.png`, sized to 384 × 384 pixels. JPEG is used for opaque artwork; PNG preserves Lumev's transparency. The site rounds their corners in CSS. Products without an icon display a letter tile.

To add another icon, place a square image at `assets/products/<product_id>/icon.jpg` or `icon.png` and set this field in the product's `index.md`:

```yaml
icon: "/assets/products/new-product/icon.png"
```

Use a 384 × 384 image for the same quality and download size as the existing icons. The content check verifies that the file exists.

## Add or update a document

1. Copy `_templates/product/privacy.md` or `_templates/product/terms.md` into the product folder, or edit the existing document.
2. Use the complete approved English text and remove the `TEMPLATE` marker.
3. Fill in `title`, `summary`, `product`, `order` and `permalink`. Use `source_url` only when the text was imported from a published ilterra.com page.
4. Keep the public `permalink` stable when updating the text. Remove any matching `external_documents` link after its Markdown replacement is ready.
5. Check factual claims against the current product, run `ruby scripts/check_content.rb`, review the rendered page and merge into `release`.

The layout displays the document title, so start sections in the Markdown body with `##`. Git history records updates to the Markdown file; there is no need to create manual archive pages or edition labels.

## GitHub Pages

The custom domain serves this site from `/`, so `_config.yml` uses `baseurl: ""`. In GitHub **Settings → Pages**, select **Deploy from a branch**, then `release` and `/(root)`. Protect `release` with pull requests, the `content` check, and restrictions on force pushes and branch deletion.

## Local checks

```bash
ruby scripts/check_content.rb
```

The check uses only Ruby's standard library. It validates product-document relationships, icon paths, source links, required metadata, unresolved legal placeholders and duplicate URLs. GitHub Actions runs it on pull requests into `release`.

Jekyll is optional on your computer because GitHub Pages performs the build. If Jekyll is installed, run `jekyll serve --baseurl ""` and open `http://127.0.0.1:4000/`.

## References

- [Publishing GitHub Pages from a branch](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)
- [Protecting branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches)
- [Jekyll documentation](https://jekyllrb.com/docs/)
