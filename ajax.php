<?php

class Ps_FeaturedProductsAjaxModuleFrontController extends ModuleFrontController
{
    public function initContent()
    {
        parent::initContent();

        $type = Tools::getValue('type', 'featured');
        $context = Context::getContext();
        $products = [];

        switch ($type) {
            case 'new':
                $products = Product::getNewProducts($context->language->id, 0, 6);
                break;

            case 'recommend':
                // Exemple simple : produits aléatoires
                $sql = new DbQuery();
                $sql->select('p.id_product');
                $sql->from('product', 'p');
                $sql->where('p.active = 1');
                $sql->orderBy('RAND()');
                $sql->limit(6);
                $ids = Db::getInstance()->executeS($sql);
                foreach ($ids as $id) {
                    $products[] = (new Product((int)$id['id_product'], false, $context->language->id))->getFields();
                }
                break;

            default:
                $id_home = Configuration::get('PS_HOME_CATEGORY');
                $category = new Category($id_home, $context->language->id);
                $products = $category->getProducts($context->language->id, 1, 6);
                break;
        }

        $html = $this->context->smarty->fetch(
            _PS_THEME_DIR_ . 'templates/catalog/_partials/productlist.tpl',
            ['products' => $products]
        );

        die(json_encode([
            'success' => true,
            'html' => $html,
        ]));
    }
}