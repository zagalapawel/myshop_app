import 'package:flutter/material.dart';
// import 'package:myshop_app/providers/orders.dart';
// import 'package:myshop_app/screens/auth_screen.dart';
import 'package:myshop_app/screens/products_overview_screen.dart';
import 'package:provider/provider.dart';

import '../screens/orders_screen.dart';
import '../screens/user_products_screen.dart';
import '../providers/auth.dart';
import '../helpers/custom_route.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          AppBar(
            title: Text('Hello Friend!'),
            automaticallyImplyLeading: false,
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.shop),
            title: Text('Shop'),
            onTap: () {
              // Navigator.of(context).pushReplacementNamed('/');
              Navigator.of(context).pushReplacement(
                DrawerCustomRoute(page: ProductsOverviewScreen()),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.payment),
            title: Text('Orders'),
            onTap: () {
              // Navigator.of(context).pushReplacementNamed(OrdersScreen.routeName);
              // Custom animation on direct route
              Navigator.of(context).pushReplacement(
                DrawerCustomRoute(page: OrdersScreen()),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Manage Products'),
            onTap: () {
              // Navigator.of(context).pushReplacementNamed(UserProductsScreen.routeName);
              Navigator.of(context).pushReplacement(
                DrawerCustomRoute(page: UserProductsScreen()),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Log out'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/');
              // Navigator.of(context).pushReplacement(
              //   DrawerCustomRoute(page: AuthScreen()),
              // );
              Provider.of<Auth>(context, listen: false).logout();
            },
          ),
        ],
      ),
    );
  }
}
